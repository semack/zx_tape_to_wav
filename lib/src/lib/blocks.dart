import 'dart:typed_data';

import 'binary_reader.dart';

abstract class BlockBase {
  int _index;

  int get index => _index;

  BlockBase(int index, BinaryReader reader) {
    _index = index;
    _loadData(reader);
  }

  void _loadData(BinaryReader reader);
}

class DataBlock extends BlockBase {
  DataBlock(int index, BinaryReader reader) : super(index, reader);

  int _pilotPulseLen;

  int get pilotPulseLen => _pilotPulseLen;
  int _firstSyncLen;

  int get firstSyncLen => _firstSyncLen;
  int _secondSyncLen;

  int get secondSyncLen => _secondSyncLen;
  int _zeroLen;

  int get zeroLen => _zeroLen;
  int _oneLen;

  int get oneLen => _oneLen;
  int _tailMs;

  int get tailMs => _tailMs;
  int _rem;

  int get rem => _rem;
  int _pilotLen;

  int get pilotLen => _pilotLen;
  Uint8List _data;

  Uint8List get data => _data;

  bool get isCheckSumValid {
    int sum = 0;
    for (int i = 0; i < data.length - 1; i++) sum ^= data[i];
    return data[data.length - 1] == sum;
  }

  @override
  void _loadData(BinaryReader reader) {
    _pilotPulseLen = 2168;
    _firstSyncLen = 667;
    _secondSyncLen = 735;
    _zeroLen = 855;
    _oneLen = 1710;
    _tailMs = 1000;
    _rem = 8;
    _pilotLen = 8083;
    var length = reader.readUint16();
    _data = reader.readUint8Array(length);
    if (_data[0] >= 128) _pilotLen = 3223;
  }
}

class ArchiveInfoBlock extends BlockBase {
  String description;

  ArchiveInfoBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    {
      var length = reader.readUint16();
      description = reader.readAsString(length);
    }
  }
}

class GroupStartBlock extends BlockBase {
  String groupName;

  GroupStartBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    var length = reader.readUint8();
    groupName = reader.readAsString(length);
  }
}

class GroupEndBlock extends BlockBase {
  @override
  void _loadData(BinaryReader reader) {
    // nothing to do
  }

  GroupEndBlock(int index, BinaryReader reader) : super(index, reader);
}

class HardwareTypeBlock extends BlockBase {
  HardwareTypeBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    var length = reader.readUint8();
    reader.skip(length * 3);
  }
}

class PauseOrStopTheTapeBlock extends BlockBase {
  int duration;

  PauseOrStopTheTapeBlock(int index, BinaryReader reader)
      : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    duration = reader.readUint16();
  }
}

class PulseSequenceBlock extends BlockBase {
  Uint16List pulses;

  PulseSequenceBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    var length = reader.readUint8();
    pulses = new Uint16List(length);
    for (var i = 0; i < length; i++) pulses[i] = reader.readUint16();
  }
}

class PureDataBlock extends DataBlock {
  PureDataBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  bool get isCheckSumValid => true;

  @override
  void _loadData(BinaryReader reader) {
    _zeroLen = reader.readUint16();
    _oneLen = reader.readUint16();
    _rem = reader.readUint8();
    _tailMs = reader.readUint16();
    var bytes = reader.readUint8Array(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.readUint8Array(length);
  }
}

class PureToneBlock extends BlockBase {
  int pulseLen;
  int pulses;

  PureToneBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    pulseLen = reader.readUint16();
    pulses = reader.readUint16();
  }
}

class StandardSpeedDataBlock extends DataBlock {
  StandardSpeedDataBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    _tailMs = reader.readUint16();
    super._loadData(reader);
  }
}

class TextDescriptionBlock extends BlockBase {
  String description;

  TextDescriptionBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    var length = reader.readUint8();
    description = reader.readAsString(length);
  }
}

class TurboSpeedDataBlock extends StandardSpeedDataBlock {
  TurboSpeedDataBlock(int index, BinaryReader reader) : super(index, reader);

  @override
  void _loadData(BinaryReader reader) {
    _pilotPulseLen = reader.readUint16();
    _firstSyncLen = reader.readUint16();
    _secondSyncLen = reader.readUint16();
    _zeroLen = reader.readUint16();
    _oneLen = reader.readUint16();
    _pilotLen = reader.readUint16();
    _rem = reader.readUint8();
    _tailMs = reader.readUint16();
    var bytes = reader.readUint8Array(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.readUint8Array(length);
  }
}
