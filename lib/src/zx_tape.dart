import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'lib/blocks.dart';
import 'lib/wav_builder.dart';

enum TapeType { unknown, tap, tzx }

class ZxTape {
  ReadBuffer? _reader;

  final List<BlockBase> _blocks = [];

  var _tapeType = TapeType.unknown;

  /// A type of source byte array (TAP or TZX)
  TapeType get tapeType => _tapeType;

  /// Static method of creating an instance of ZxTape object.
  /// Incoming byte array must be specified.
  static Future<ZxTape> create(Uint8List bytes) async {
    var tape = ZxTape._create(bytes.buffer.asByteData());
    return tape;
  }

  final ByteData _data;

  ZxTape._create(this._data){
    _tapeType = _detectTapeType(_data);
  }

  Future _load() async {
    if (_tapeType == TapeType.unknown)
      throw new ArgumentError('Incompatible data format.');

    _reader = ReadBuffer(_data);

    // skipping headers
    switch (_tapeType) {
      case TapeType.tzx:
        // skipping header, setting zero position for rich data
        _reader!.getUint8List(10);
        break;
      default:
        break;
    }

    var index = 0;
    while (_reader!.hasRemaining) {
      var block = await _readBlock(index);
      _blocks.add(block!);
      index++;
    }
    _blocks.add(PauseOrStopTheTapeBlock(index, _reader!, duration: 2000));
  }

  /// Returns WAV content as array of bytes.
  Future<Uint8List> toWavBytes(
      {int frequency = 44100,
      bool boosted = true,
      Function(double percents)? progress}) async {

    if (_blocks.isEmpty)
      await _load();

    var builder = WavBuilder(_blocks, frequency, progress,
        boosted: boosted);
    return builder.toBytes();
  }

  static TapeType _detectTapeType(ByteData data)  {
    try {
      // checking tzx
      var reader = ReadBuffer(data);
      var magic = reader.getInt64();
      if (magic == 0x1a2165706154585a) {
        return TapeType.tzx;
      }
      // checking tap
      reader = ReadBuffer(data);
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
