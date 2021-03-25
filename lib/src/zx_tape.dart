import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'lib/blocks.dart';
import 'lib/wav_builder.dart';

enum TapeType { unknown, tap, tzx }

class ZxTape {
  ReadBuffer? _reader;

  final List<BlockBase?> _blocks = [];

  /// A list of recognized data blocks
  Iterable<BlockBase?> get blocks => _blocks;

  var _tapeType = TapeType.unknown;

  /// A type of source byte array (TAP or TZX)
  TapeType get tapeType => _tapeType;

  /// Static method of creating an instance of ZxTape object.
  /// Incoming byte array must be specified.
  static Future<ZxTape> create(Uint8List bytes) async {
    var tape = ZxTape._create(bytes.buffer.asByteData());
    await tape._load();
    return tape;
  }

  ZxTape._create(ByteData data) {
    _reader = ReadBuffer(data);
  }

  Future _load() async {
    _tapeType = await _detectFileType();
    if (_tapeType == TapeType.unknown)
      throw new ArgumentError('Incompatible data format.');

    var index = 0;
    while (_reader!.hasRemaining) {
      var block = await _readBlock(index);
      if (block != null) {
        _blocks.add(block);
        index++;
      }
    }
    _blocks.add(PauseOrStopTheTapeBlock(index, _reader!, duration: 2000));
  }

  /// Returns WAV content as array of bytes.
  Future<Uint8List> toWavBytes(
      {int frequency = 44100,
      bool boosted = true,
      Function(double percents)? progress}) async {
    var builder = WavBuilder(blocks as List<BlockBase?>, frequency, progress,
        boosted: boosted);
    return builder.toBytes();
  }

  Future<TapeType> _detectFileType() async {
    try {
      // checking tzx
      var reader = ReadBuffer(_reader!.data);
      var magic = reader.getInt64();
      if (magic == 0x1a2165706154585a) {
        // skipping header, setting zero position for rich data
        _reader!.getUint8List(10);
        return TapeType.tzx;
      }
      // checking tap
      reader = ReadBuffer(_reader!.data);
      var testBlock = DataBlock(0, reader);
      if (testBlock.isCheckSumValid) return TapeType.tap;
    } catch (e) {}

    return TapeType.unknown;
  }

  Future<BlockBase?> _readBlock(int index) async {
    var reader = _reader!;

    switch (_tapeType) {
      case TapeType.tap:
        return DataBlock(index, reader);
      case TapeType.tzx:
        var blockType = reader.getUint8();
        switch (blockType) {
          case 0x0:
            return null;
          case 0x10:
            return StandardSpeedDataBlock(index, reader);
          case 0x11:
            return TurboSpeedDataBlock(index, reader);
          case 0x12:
            return PureToneBlock(index, reader);
          case 0x13:
            return PulseSequenceBlock(index, reader);
          case 0x14:
            return PureDataBlock(index, reader);
          case 0x20:
          case 0x2A:
            return PauseOrStopTheTapeBlock(index, reader);
          case 0x21:
            return GroupStartBlock(index, reader);
          case 0x22:
            return GroupEndBlock(index, reader);
          case 0x23:
            return JumpToBlock(index, reader);
          case 0x24:
            return LoopStartBlock(index, reader);
          case 0x25:
            return LoopEndBlock(index, reader);
          case 0x28:
            return SelectBlock(index, reader);
          case 0x30:
            return TextDescriptionBlock(index, reader);
          case 0x31:
            return MessageBlock(index, reader);
          case 0x32:
            return ArchiveInfoBlock(index, reader);
          case 0x33:
            return HardwareTypeBlock(index, reader);
          case 0x35:
            return CustomInfoBlock(index, reader);
          case 0x5A:
            return GlueBlock(index, reader);
          default:
            throw new ArgumentError(
                'Unexpected type 0x${blockType.toRadixString(16)} of block #$index');
        }
      default:
        return null;
    }
  }
}
