import 'dart:typed_data';

import 'package:wave_builder/wave_builder.dart';
import 'package:zx_tape_to_wav/src/lib/binary_writer.dart';

import 'blocks.dart';

class WavBuilder {
  static Uint8List build(List<BlockBase> blocks, {int frequency = 22050}) {
    var builder = new WaveBuilder();

    blocks.forEach((block) async {
      _fillSoundData(builder, block, frequency, true);
    });

    return Uint8List.fromList(builder.fileBytes);
  }

  WavBuilder._();

  static _doSignal(
      BinaryWriter writer, int signalLevel, int clks, int frequency) {
    var sampleNanoSec = 1000000000 / frequency;
    var cpuClkNanoSec = 286;
    var samples = (cpuClkNanoSec * clks / sampleNanoSec).round();

    for (var i = 0; i < samples; i++) writer.writeUint8(signalLevel);
  }

  static _writeDataByte(BinaryWriter writer, DataBlock block, int byte, int hi,
      int lo, int frequency) {
    int mask = 0x80;

    while (mask != 0) {
      var len = (byte & mask) == 0 ? block.zeroLen : block.oneLen;
      _doSignal(writer, hi, len, frequency);
      _doSignal(writer, lo, len, frequency);
      mask >>= 1;
    }
  }

  static _fillSoundData(WaveBuilder builder, BlockBase block, int frequency, bool amplifySoundSignal) {
    int hi, lo;
    if (amplifySoundSignal)
    {
      hi = 0xFF;
      lo = 0x00;
    }
    else
    {
      hi = 0xC0;
      lo = 0x40;
    }
    if (block is DataBlock) {
      var writer = BinaryWriter();
      var signalState = hi;
      for (var i = 0; i < block.pilotLen; i++) {
        _doSignal(writer, signalState, block.pilotPulseLen, frequency);
        signalState = signalState == hi ? lo : hi;
      }

      // pilot
      if (signalState == lo)
        _doSignal(writer, lo, block.pilotPulseLen, frequency);

      _doSignal(writer, hi, block.firstSyncLen, frequency);
      _doSignal(writer, lo, block.secondSyncLen, frequency);

      // writing data
      block.data.forEach((byte) {
        _writeDataByte(writer, block, byte, hi, lo, frequency);
      });

      // last sync3
      for (var i = 7; i >= 8 - block.rem; i--) {
        var len = block.zeroLen;
        if ((block.data[block.data.length - 1] & (1 << i)) != 0)
          len = block.oneLen;
        _doSignal(writer, hi, len, frequency);
        _doSignal(writer, lo, len, frequency);
      }

      builder.appendFileContents(writer.toBytes());

      // adding pause
      if (block.tailMs > 0)
        builder.appendSilence(
            block.tailMs, WaveBuilderSilenceType.EndOfLastSample);
    } else if (block is PauseOrStopTheTapeBlock) {
      builder.appendSilence(
          block.duration, WaveBuilderSilenceType.EndOfLastSample);
    } else if (block is PulseSequenceBlock) {
      var writer = BinaryWriter();
      block.pulses.forEach((pulse) {
        _doSignal(writer, hi, pulse, frequency);
        _doSignal(writer, lo, pulse, frequency);
      });
      builder.appendFileContents(writer.toBytes());
    } else if (block is PureToneBlock) {
      var writer = BinaryWriter();
      for (var i = 0; i < block.pulses; i++) {
        _doSignal(writer, hi, block.pulseLen, frequency);
        _doSignal(writer, lo, block.pulseLen, frequency);
      }
      builder.appendFileContents(writer.toBytes());
    }
  }
}
