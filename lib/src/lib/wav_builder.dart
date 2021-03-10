import 'dart:convert';
import 'dart:typed_data';

import 'blocks.dart';
import 'extensions.dart';

class WavBuilder {
  List<BlockBase> _blocks;
  final Function(double percents) _progress;
  final List<int> _bytes = [];
  final int _frequency;
  double _cpuTimeStamp = 0;
  double _sndTimeStamp = 0;
  double _cpuTimeBase = 0;
  double _sndTimeBase = 0;
  bool _currentLevel = false;
  final int _cpuFreq = 3500000;
  final bool _amplifySignal;

  final bool _stereo;

  WavBuilder(List<BlockBase> blocks, this._frequency, this._stereo,
      this._amplifySignal, this._progress) {
    if (_frequency < 11025)
      throw new ArgumentError('Invalid frequency specified $_frequency');

    _blocks = blocks;

    var timeBase = _getLCM(_frequency, _cpuFreq);
    _cpuTimeBase = timeBase / _cpuFreq;
    _sndTimeBase = timeBase / _frequency;
  }

  Uint8List toBytes() {
    int loopRepetitions;
    int loopIndex;
    for (var i = 0; i < _blocks.length; i++) {
      var block = _blocks[i];
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
        if (_progress != null) {
          var percents = 100.0;
          if (i < _blocks.length - 1) percents = (100 / _blocks.length) * i;
          _progress(percents);
        }
      }
    }
    _fillHeader();
    return Uint8List.fromList(_bytes);
  }

  void _addBlockSoundData(BlockBase block) {
    if (block is DataBlock) {
      if (block is! PureDataBlock) {
        for (var i = 0; i < block.pilotLen; i++) {
          addEdge(block.pilotPulseLen);
        }
        addEdge(block.firstSyncLen);
        addEdge(block.secondSyncLen);
      }

      for (var i = 0; i < block.data.length - 1; i++) {
        var d = block.data[i];
        for (var j = 7; j >= 0; j--) {
          var bit = d & (1 << j) != 0;

          if (bit) {
            addEdge(block.oneLen);
            addEdge(block.oneLen);
          } else {
            addEdge(block.zeroLen);
            addEdge(block.zeroLen);
          }
        }
      }

      // Last byte
      var d = block.data[block.data.length - 1];

      for (var i = 7; i >= (8 - block.rem); i--) {
        var bit = d & (1 << i) != 0;

        if (bit) {
          addEdge(block.oneLen);
          addEdge(block.oneLen);
        } else {
          addEdge(block.zeroLen);
          addEdge(block.zeroLen);
        }
      }

      if (block.tailMs > 0) {
        addPause(block.tailMs);
      }
    } else if (block is PureToneBlock) {
      for (var i = 0; i < block.pulses; i++) {
        addEdge(block.pulseLen);
      }
    } else if (block is PulseSequenceBlock) {
      block.pulses.forEach((pulse) {
        addEdge(pulse);
      });
    } else if (block is PauseOrStopTheTapeBlock) {
      addPause(block.duration);
    }
  }

  void addEdge(int len) {
    var hi = 0xC0;
    var lo = 0x40;
    if (_amplifySignal) {
      hi = 0xFF;
      lo = 0x00;
    }
    var lvl = lo;
    if (_currentLevel) {
      lvl = hi;
    }
    appendLevel(len, lvl);
    _currentLevel = !_currentLevel;
  }

  void addPause(int milliSeconds) {
    var ll = milliSeconds - 1;
    var msl = _cpuFreq ~/ 1000;
    addEdge(msl);

    // if last edge is fall, issue another rise for 2 ms
    if (_currentLevel) {
      addEdge(msl * 2);
      ll -= 2;
    }
    appendLevel(ll * msl, 0);
    _currentLevel = false;
  }

  void appendLevel(int len, int lvl) {
    _cpuTimeStamp += len * _cpuTimeBase;
    while (_sndTimeStamp < _cpuTimeStamp) {
      if (_stereo) _bytes.add(lvl);
      _bytes.add(lvl);
      _sndTimeStamp += _sndTimeBase;
    }
  }

  void _fillHeader() {
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
    header.addAll(1.asByteList(2));
    //   uint16_t channels; // 2 for stereo
    header.addAll(_stereo ? 2.asByteList(2) : 1.asByteList(2));
    //   uint32_t sps;      // samples/sec
    header.addAll(_frequency.asByteList(4));
    //   uint32_t srate;    // sample rate in bytes/sec (block align)
    header.addAll(_frequency.asByteList(4));
    //   uint16_t chan8;    // channels * bits/sample / 8
    header.addAll(1.asByteList(2));
    //   uint16_t bps;      // bits/sample
    header.addAll(8.asByteList(2));
    //   char data[4];      // should be "data"
    header.addAll(utf8encoder.convert('data'));
    //   uint32_t datlen;   // length of data block
    header.addAll(_bytes.length.asByteList(4));

    _bytes.insertAll(0, header);
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
