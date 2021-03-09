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

  WavBuilder(List<BlockBase> blocks, this._frequency, this._progress) {
    if (_frequency < 11025)
      throw new ArgumentError('Invalid frequency specified $_frequency');

    _blocks = blocks;

    var timeBase = _getLCM(_frequency, _cpuFreq);
    _cpuTimeBase = timeBase / _cpuFreq;
    _sndTimeBase = timeBase / _frequency;
  }

  Uint8List toBytes() {
    LoopStartBlock loopStartBlock;
    for (var i = 0; i < _blocks.length; i++) {
      var block = _blocks[i];
      if (block is LoopStartBlock)
        loopStartBlock = block;
      else if (block is LoopEndBlock) {
        loopStartBlock.repetitions--;
        if (loopStartBlock.repetitions > 0) i = loopStartBlock.index;
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
    var lvl = -16384;
    if (_currentLevel) {
      lvl = 16384;
    }
    // var lvl = 0;
    // if (_currentLevel) {
    //   lvl = 65280;
    // }
    // var lvl = 65280;
    // if (_currentLevel) {
    //   lvl = 0;
    // }
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
      // _bytes.add(0); // bitrate 8
      _bytes.add(lvl >> 8);
      _bytes.add(lvl >> 8);
      _sndTimeStamp += _sndTimeBase;
    }
  }

  void _fillHeader() {
    const int NUM_CHANNELS = 2;
    const int BIT_RATE = 8;
    const int RIFF_CHUNK_SIZE_INDEX = 4;
    const int SUB_CHUNK_SIZE = 16;
    const int AUDIO_FORMAT = 1;
    const int BYTE_SIZE = 8;

    var blockAlign = NUM_CHANNELS * BIT_RATE ~/ BYTE_SIZE,
        byteRate = _frequency * blockAlign,
        bitsPerSample = BIT_RATE;

    final List<int> header = [];
    final utf8encoder = new Utf8Encoder();

    header.addAll(utf8encoder.convert('RIFF'));
    header.addAll((_bytes.length - RIFF_CHUNK_SIZE_INDEX).asByteList(4));
    header.addAll(utf8encoder.convert('WAVEfmt '));
    header.addAll(SUB_CHUNK_SIZE.asByteList(4));
    header.addAll(AUDIO_FORMAT.asByteList(2));
    header.addAll(NUM_CHANNELS.asByteList(2));
    header.addAll(_frequency.asByteList(4));
    header.addAll(byteRate.asByteList(4));
    header.addAll(blockAlign.asByteList(2));
    header.addAll(bitsPerSample.asByteList(2));
    header.addAll(utf8encoder.convert('data'));
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
