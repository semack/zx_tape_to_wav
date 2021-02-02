import 'dart:convert';
import 'dart:typed_data';

import 'blocks.dart';

class WavBuilder {
  List<BlockBase> _blocks;
  int _frequency;
  bool _amplifySoundSignal;
  final List<int> _bytes = [];

  WavBuilder(List<BlockBase> blocks, int frequency, bool amplifySoundSignal) {
    _blocks = blocks;
    if (frequency < 11025)
      throw new ArgumentError('Invalid frequency specified $_frequency');
    _frequency = frequency;
    _amplifySoundSignal = amplifySoundSignal;
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
      if (block.pilotLen != null && block.pilotLen > 0) {
        // pilot
        var signalState = hi;
        for (var i = 0; i < block.pilotLen; i++) {
          _doSignal(signalState, block.pilotPulseLen);
          signalState = signalState == hi ? lo : hi;
        }
        if (signalState == lo) _doSignal(lo, block.pilotPulseLen);

        // sync
        _doSignal(hi, block.firstSyncLen);
        _doSignal(lo, block.secondSyncLen);
      }

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

  void _writePause(int ms) {
    for (var i = 0; i < _frequency * (ms / 1000); i++) _bytes.add(0x00);
  }

  void _doSignal(int signalLevel, int clks) {
    var sampleNanoSec = 1000000000 / _frequency;
    var cpuClkNanoSec = 286;
    var samples = (cpuClkNanoSec * clks / sampleNanoSec).round();

    for (var i = 0; i < samples; i++) _bytes.add(signalLevel);
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

  void _fillHeader() {
    const int NUM_CHANNELS = 1;
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
    header.addAll(_numberAsByteList(_bytes.length - RIFF_CHUNK_SIZE_INDEX, 4));
    header.addAll(utf8encoder.convert('WAVEfmt '));
    header.addAll(_numberAsByteList(SUB_CHUNK_SIZE, 4));
    header.addAll(_numberAsByteList(AUDIO_FORMAT, 2));
    header.addAll(_numberAsByteList(NUM_CHANNELS, 2));
    header.addAll(_numberAsByteList(_frequency, 4));
    header.addAll(_numberAsByteList(byteRate, 4));
    header.addAll(_numberAsByteList(blockAlign, 2));
    header.addAll(_numberAsByteList(bitsPerSample, 2));
    header.addAll(utf8encoder.convert('data'));
    header.addAll(_numberAsByteList(_bytes.length, 4));

    _bytes.insertAll(0, header);
  }

  Uint8List toBytes() {
    _blocks.forEach((block) {
      _addBlockSoundData(block);
    });
    _fillHeader();
    return Uint8List.fromList(_bytes);
  }

  static List<int> _numberAsByteList(int input, numBytes,
      {Endian endian = Endian.little}) {
    var output = <int>[], curByte = input;
    for (var i = 0; i < numBytes; ++i) {
      output.insert(endian == Endian.big ? 0 : output.length, curByte & 255);
      curByte >>= 8;
    }
    return output;
  }
}
