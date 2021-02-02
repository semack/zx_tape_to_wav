import 'dart:typed_data';

import 'lib/binary_reader.dart';
import 'lib/blocks.dart';
import 'lib/wav_builder.dart';

enum TapeFileType { unknown, tap, tzx }

class ZxTape {
  BinaryReader _reader;

  List<BlockBase> _blocks = [];

  /// A list of recognized data blocks
  List<BlockBase> get blocks => _blocks;

  var _tapeFileType = TapeFileType.unknown;

  /// A type of source byte array (TAP or TZX)
  TapeFileType get tapeFileType => _tapeFileType;

  /// Static method of creating an instance of ZxTape object.
  /// Incoming byte array must be specified.
  static Future<ZxTape> create(Uint8List bytes) async {
    var tape = ZxTape._create(bytes.buffer.asByteData());
    await tape._load();
    return tape;
  }

  ZxTape._create(ByteData data) {
    _reader = new BinaryReader(data);
  }

  Future _load() async {
    _tapeFileType = await _detectFileType();
    if (_tapeFileType == TapeFileType.unknown)
      throw new ArgumentError('Incompatible data format.');

    var index = 0;
    while (!_reader.isEOF()) {
      var block = await _readBlock(index);
      _blocks.add(block);
      index++;
    }
  }

  /// Returns WAV content as array of bytes.
  Future<Uint8List> toWavBytes(
      {int frequency = 22050, bool amplifySoundSignal = false}) async {
    var builder = new WavBuilder(blocks, frequency, amplifySoundSignal);
    return builder.toBytes();
  }

  Future<TapeFileType> _detectFileType() async {
    try {
      // checking tzx
      var reader = BinaryReader(_reader.raw);
      var magic = reader.readInt64();
      if (magic == 0x1a2165706154585a) {
        // skipping header, setting zero position for rich data
        _reader.skip(10);
        return TapeFileType.tzx;
      }
      // checking tap
      reader = BinaryReader(_reader.raw);
      var testBlock = new DataBlock(0, reader);
      if (testBlock.isCheckSumValid) return TapeFileType.tap;
    } catch (e) {}

    return TapeFileType.unknown;
  }

  Future<BlockBase> _readBlock(int index) async {
    switch (_tapeFileType) {
      case TapeFileType.tap:
        return new DataBlock(index, _reader);
      case TapeFileType.tzx:
        var blockType = _reader.readUint8();
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
            return new PauseOrStopTheTapeBlock(index, _reader);
          case 0x21:
            return new GroupStartBlock(index, _reader);
          case 0x22:
            return new GroupEndBlock(index, _reader);
          case 0x30:
            return new TextDescriptionBlock(index, _reader);
          case 0x32:
            return new ArchiveInfoBlock(index, _reader);
          case 0x33:
            return new HardwareTypeBlock(index, _reader);
          default:
            throw new ArgumentError(
                'Unexpected type $blockType of block #$index');
        }
        break;
      default:
        return null;
    }
  }
}
