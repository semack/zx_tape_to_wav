import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'lib/blocks.dart';
import 'lib/wav_builder.dart';

enum TapeType { unknown, tap, tzx }

class ZxTape {
  ReadBuffer _reader;

  final List<BlockBase> _blocks = [];

  /// A list of recognized data blocks
  Iterable<BlockBase> get blocks => _blocks;

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
    _reader = new ReadBuffer(data);
  }

  Future _load() async {
    _tapeType = await _detectFileType();
    if (_tapeType == TapeType.unknown)
      throw new ArgumentError('Incompatible data format.');

    var index = 0;
    while (_reader.hasRemaining) {
      var block = await _readBlock(index);
      _blocks.add(block);
      index++;
    }
  }

  /// Returns WAV content as array of bytes.
  Future<Uint8List> toWavBytes(
      {int frequency = 44100,
      int bitsPerSample = 8,
      bool amplifySignal = false,
      Function(double percents) progress}) async {
    var builder =
        WavBuilder(blocks, frequency, bitsPerSample, amplifySignal, progress);
    return builder.toBytes();
  }

  Future<TapeType> _detectFileType() async {
    try {
      // checking tzx
      var reader = ReadBuffer(_reader.data);
      var magic = reader.getInt64();
      if (magic == 0x1a2165706154585a) {
        // skipping header, setting zero position for rich data
        _reader.getUint8List(10);
        return TapeType.tzx;
      }
      // checking tap
      reader = ReadBuffer(_reader.data);
      var testBlock = DataBlock(0, reader);
      if (testBlock.isCheckSumValid) return TapeType.tap;
    } catch (e) {}

    return TapeType.unknown;
  }

  Future<BlockBase> _readBlock(int index) async {
    switch (_tapeType) {
      case TapeType.tap:
        return new DataBlock(index, _reader);
      case TapeType.tzx:
        var blockType = _reader.getUint8();
        switch (blockType) {
          case 0x10:
            return new StandardSpeedDataBlock(index, _reader);
          case 0x11:
            return new TurboSpeedDataBlock(index, _reader);
          case 0x12:
            return new PureToneBlock(index, _reader);
          case 0x13:
            return new PulseSequenceBlock(index, _reader);
          case 0x14:
            return new PureDataBlock(index, _reader);
          case 0x20:
          case 0x2A:
            return new PauseOrStopTheTapeBlock(index, _reader);
          case 0x21:
            return new GroupStartBlock(index, _reader);
          case 0x22:
            return new GroupEndBlock(index, _reader);
          case 0x23:
            return new JumpToBlock(index, _reader);
          case 0x24:
            return new LoopStartBlock(index, _reader);
          case 0x25:
            return new LoopEndBlock(index, _reader);
          case 0x28:
            return new SelectBlock(index, _reader);
          case 0x30:
            return new TextDescriptionBlock(index, _reader);
          case 0x31:
            return new MessageBlock(index, _reader);
          case 0x32:
            return new ArchiveInfoBlock(index, _reader);
          case 0x33:
            return new HardwareTypeBlock(index, _reader);
          case 0x35:
            return new CustomInfoBlock(index, _reader);
          case 0x5A:
            return new GlueBlock(index, _reader);
          default:
            throw new ArgumentError(
                'Unexpected type 0x${blockType.toRadixString(16)} of block #$index');
        }
        break;
      default:
        return null;
    }
  }
}
