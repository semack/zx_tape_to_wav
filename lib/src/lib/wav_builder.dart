import 'dart:convert';
import 'dart:typed_data';

import 'blocks.dart';
import 'extensions.dart';

class WavBuilder {
  final List<int> _bytes = [];
  double _cpuTimeStamp = 0;
  double _sndTimeStamp = 0;
  double _cpuTimeBase = 0;
  double _sndTimeBase = 0;
  bool _currentLevel = false;
  final int _cpuFreq = 3500000;
  final List<BlockBase> blocks;
  final int frequency;
  final int bits;
  final bool amplifySignal;
  final Function(double percents) progress;

  WavBuilder(this.blocks, this.frequency, this.bits,
      this.amplifySignal, this.progress) {
    if (frequency < 11025)
      throw new ArgumentError('Invalid frequency specified $frequency');
    var timeBase = _getLCM(frequency, _cpuFreq);
    _cpuTimeBase = timeBase / _cpuFreq;
    _sndTimeBase = timeBase / frequency;
  }

  Uint8List toBytes() {
    int loopRepetitions;
    int loopIndex;
    for (var i = 0; i < blocks.length; i++) {
      var block = blocks[i];
      if (block is LoopStartBlock) {
        loopIndex = block.index;
        loopRepetitions = block.repetitions;
      } else if (block is LoopEndBlock) {
        loopRepetitions--;
        if (loopRepetitions > 0) i = loopIndex;
      } else if (block is JumpToBlock)
        i += block.offset;
      else {
        _addBlockSoundData(block);
        if (progress != null) {
          var percents = 100.0;
          if (i < blocks.length - 1) percents = (100 / blocks.length) * i;
          progress(percents);
        }
      }
    }
    _fillHeader(_bytes, frequency, bits);
    return Uint8List.fromList(_bytes);
  }

  void _addBlockSoundData(BlockBase block) {
    if (block is DataBlock) {
      if (block is! PureDataBlock) {
        // pilotLen != 0
        for (var i = 0; i < block.pilotLen; i++) {
          _addEdge(block.pilotPulseLen);
        }
        _addEdge(block.firstSyncLen);
        _addEdge(block.secondSyncLen);
      }

      for (var i = 0; i < block.data.length - 1; i++) {
        var d = block.data[i];
        for (var j = 7; j >= 0; j--) {
          var bit = d & (1 << j) != 0;

          if (bit) {
            _addEdge(block.oneLen);
            _addEdge(block.oneLen);
          } else {
            _addEdge(block.zeroLen);
            _addEdge(block.zeroLen);
          }
        }
      }

      // Last byte
      var d = block.data[block.data.length - 1];

      for (var i = 7; i >= (8 - block.rem); i--) {
        var bit = d & (1 << i) != 0;

        if (bit) {
          _addEdge(block.oneLen);
          _addEdge(block.oneLen);
        } else {
          _addEdge(block.zeroLen);
          _addEdge(block.zeroLen);
        }
      }

      if (block.tailMs > 0) {
        _addPause(block.tailMs);
      }
    } else if (block is PureToneBlock) {
      for (var i = 0; i < block.pulses; i++) {
        _addEdge(block.pulseLen);
      }
    } else if (block is PulseSequenceBlock) {
      block.pulses.forEach((pulse) {
        _addEdge(pulse);
      });
    } else if (block is PauseOrStopTheTapeBlock) {
      _addPause(block.duration);
    }
  }

  void _appendLevel(int len, int lvl, {int db = -45}) {
    // double multiplier = pow(10, db / 20);
    // lvl = (lvl * multiplier).round();
    // if (lvl > 32768) {
    //   lvl = 32768;
    // } else if (lvl < -32768) {
    //   lvl = -32768;
    // }
    _cpuTimeStamp += len * _cpuTimeBase;
    while (_sndTimeStamp <= _cpuTimeStamp) {
      for (var i = 0; i < bits ~/ 8; i++) {
        _bytes.add(lvl >> 8);
      }
      _sndTimeStamp += _sndTimeBase;
    }
  }

  void _addEdge(int len) {
    var hi = 16384;
    var lo = -16384;
    if (amplifySignal) {
      hi = 32768;
      lo = -32768;
    }
    var lvl = lo;
    if (_currentLevel) {
      lvl = hi;
    }
    _appendLevel(len, lvl);
    _currentLevel = !_currentLevel;
  }

  void _addPause(int milliSeconds) {
    var ll = milliSeconds - 1;
    var msl = _cpuFreq ~/ 1000;
    _addEdge(msl);

    //if last edge is fall, issue another rise for 2 ms
    if (_currentLevel) {
      _addEdge(msl * 2);
      ll -= 2;
    }
    _appendLevel(ll * msl, 0);
    _currentLevel = false;
  }

  void _fillHeader(List<int> bytes, int frequency, int bitsPerSample,
      {int channels = 1, int audioFormat = 1}) {
    final List<int> header = [];
    final utf8encoder = new Utf8Encoder();

    //   char riff[4];  // should be "RIFF"
    header.addAll(utf8encoder.convert('RIFF'));
    //   uint32_t len8; // file length - 8
    header.addAll((_bytes.length - 8).asByteList(4));
    //   char wave[4];  // should be "WAVE"
    header.addAll(utf8encoder.convert('WAVE'));
    //   char fmt[4];   // should be "fmt "
    header.addAll(utf8encoder.convert('fmt '));
    //   uint32_t fdatalen; // should be 16 (0x10)
    header.addAll(16.asByteList(4));
    //   uint16_t ftag;     // format tag, 1 = pcm
    header.addAll(audioFormat.asByteList(2));
    //   uint16_t channels; // 2 for stereo
    header.addAll(channels.asByteList(2));
    //   uint32_t sps;      // samples/sec
    header.addAll(frequency.asByteList(4));
    //   uint32_t srate;    // sample rate in bytes/sec (block align)
    header.addAll(frequency.asByteList(4));
    //   uint16_t chan8;    // channels * bits/sample / 8
    header.addAll((channels * bitsPerSample ~/ 8).asByteList(2));
    //   uint16_t bps;      // bits/sample
    header.addAll(bitsPerSample.asByteList(2));
    //   char data[4];      // should be "data"
    header.addAll(utf8encoder.convert('data'));
    //   uint32_t datlen;   // length of data block
    header.addAll(bytes.length.asByteList(4));

    bytes.insertAll(0, header);
  }

  int _getLCM(int a, int b) {
    if (a == b) {
      return a;
    }
    var min = a;
    var max = b;
    if (a > b) {
      var temp = a;
      a = b;
      b = temp;
    }
    var mm = min * max;
    var c = max;
    while (c < mm) {
      if (c % min == 0 && c % max == 0) {
        return c;
      }
      c += max;
    }
    return mm;
  }
}
