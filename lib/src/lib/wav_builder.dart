import 'dart:typed_data';

import 'package:zx_tape_to_wav/src/lib/binary_writer.dart';

import 'blocks.dart';

class WavBuilder {
  List<BlockBase> _blocks;
  int _frequency;
  bool _amplifySoundSignal;
  var _writer = new BinaryWriter();

  WavBuilder(List<BlockBase> blocks,
      {int frequency = 22050, bool amplifySoundSignal = false}) {
    _blocks = blocks;
    _frequency = frequency;
    _amplifySoundSignal = amplifySoundSignal;
  }

  Uint8List toBytes() {
    _blocks.forEach((block) {
      _addBlockSoundData(block);
    });
    return _writer.toBytes();
  }

  void _doSignal(int signalLevel, int clks) {
    var sampleNanoSec = 1000000000 / _frequency;
    var cpuClkNanoSec = 286;
    var samples = (cpuClkNanoSec * clks / sampleNanoSec).round();

    for (var i = 0; i < samples; i++) _writer.writeUint8(signalLevel);
  }

  void _writeDataByte(DataBlock block, int byte, int hi, int lo) {
    int mask = 0x80;

    while (mask != 0) {
      var len = (byte & mask) == 0 ? block.zeroLen : block.oneLen;
      _doSignal(hi, len);
      _doSignal(lo, len);
      mask >>= 1;
    }
  }

  void _writePause(int ms) {
    for (var i = 0; i < _frequency * (ms / 1000); i++) _writer.writeUint8(0x00);
  }

  void _addBlockSoundData(BlockBase block) {
    int hi, lo;
    if (_amplifySoundSignal) {
      hi = 0xFF;
      lo = 0x00;
    } else {
      hi = 0xC0;
      lo = 0x40;
    }
    if (block is DataBlock) {
      var signalState = hi;
      for (var i = 0; i < block.pilotLen; i++) {
        _doSignal(signalState, block.pilotPulseLen);
        signalState = signalState == hi ? lo : hi;
      }

      // pilot
      if (signalState == lo) _doSignal(lo, block.pilotPulseLen);

      _doSignal(hi, block.firstSyncLen);
      _doSignal(lo, block.secondSyncLen);

      // writing data
      block.data.forEach((byte) {
        _writeDataByte(block, byte, hi, lo);
      });

      // last sync3
      for (var i = 7; i >= 8 - block.rem; i--) {
        var len = block.zeroLen;
        if ((block.data[block.data.length - 1] & (1 << i)) != 0)
          len = block.oneLen;
        _doSignal(hi, len);
        _doSignal(lo, len);
      }

      // adding pause
      if (block.tailMs > 0) _writePause(block.tailMs);
    } else if (block is PauseOrStopTheTapeBlock) {
      _writePause(block.duration);
    } else if (block is PulseSequenceBlock) {
      block.pulses.forEach((pulse) {
        _doSignal(hi, pulse);
        _doSignal(lo, pulse);
      });
    } else if (block is PureToneBlock) {
      for (var i = 0; i < block.pulses; i++) {
        _doSignal(hi, block.pulseLen);
        _doSignal(lo, block.pulseLen);
      }
    }
  }
}
