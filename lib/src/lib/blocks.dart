import 'dart:typed_data';

import 'package:flutter/foundation.dart';

abstract class BlockBase {
  int _index;

  int get index => _index;

  BlockBase(int index, ReadBuffer reader) {
    _index = index;
    _loadData(reader);
  }

  void _loadData(ReadBuffer reader);
}

class DataBlock extends BlockBase {
  DataBlock(int index, ReadBuffer reader) : super(index, reader);

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
  void _loadData(ReadBuffer reader) {
    _pilotPulseLen = 2168;
    _firstSyncLen = 667;
    _secondSyncLen = 735;
    _zeroLen = 855;
    _oneLen = 1710;
    _tailMs = 1000;
    _rem = 8;
    _pilotLen = 8083;
    var length = reader.getUint16();
    _data = reader.getUint8List(length);
    if (_data[0] >= 128) _pilotLen = 3223;
  }
}

class ArchiveInfoBlock extends BlockBase {
  String description;

  ArchiveInfoBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    {
      var length = reader.getUint16();
      description = String.fromCharCodes(reader.getUint8List(length));
    }
  }
}

class GroupStartBlock extends BlockBase {
  String groupName;

  GroupStartBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    groupName = String.fromCharCodes(reader.getUint8List(length));
  }
}

class GroupEndBlock extends BlockBase {
  @override
  void _loadData(ReadBuffer reader) {
    // nothing to do
  }

  GroupEndBlock(int index, ReadBuffer reader) : super(index, reader);
}

class LoopStartBlock extends BlockBase {
  int repetitions;

  LoopStartBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    repetitions  = reader.getUint16();
  }
}

class JumpToBlock extends BlockBase {
  int offset;

  JumpToBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    offset  = reader.getUint16();
  }
}

class LoopEndBlock extends BlockBase {
  @override
  void _loadData(ReadBuffer reader) {
    // nothing to do
  }

  LoopEndBlock(int index, ReadBuffer reader) : super(index, reader);
}

class GlueBlock extends BlockBase {

  GlueBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    reader.getUint8List(9);
  }
}

class HardwareInfo {
  final int hardwareType;
  final int hardwareId;
  final int hardwareInfo;

  HardwareInfo(this.hardwareType, this.hardwareId, this.hardwareInfo);
}

class HardwareTypeBlock extends BlockBase {
  HardwareTypeBlock(int index, ReadBuffer reader) : super(index, reader);

  Iterable<HardwareInfo> get hardwareInfo => _hardwareInfo;
  List<HardwareInfo> _hardwareInfo = [];

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    for (int i = 0; i < length; i++) {
      var info = new HardwareInfo(
          reader.getUint8(), reader.getUint8(), reader.getUint8());
      _hardwareInfo.add(info);
    }
  }
}

class PauseOrStopTheTapeBlock extends BlockBase {
  int duration;

  PauseOrStopTheTapeBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    duration = reader.getUint16();
  }
}

class PulseSequenceBlock extends BlockBase {
  Uint16List pulses;

  PulseSequenceBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    pulses = new Uint16List(length);
    for (var i = 0; i < length; i++) pulses[i] = reader.getUint16();
  }
}

class PureDataBlock extends DataBlock {
  PureDataBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  bool get isCheckSumValid => true;

  @override
  void _loadData(ReadBuffer reader) {
    _zeroLen = reader.getUint16();
    _oneLen = reader.getUint16();
    _rem = reader.getUint8();
    //_tailMs =
        reader.getUint16();
    var bytes = reader.getUint8List(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.getUint8List(length);
  }
}

class PureToneBlock extends BlockBase {
  int pulseLen;
  int pulses;

  PureToneBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    pulseLen = reader.getUint16();
    pulses = reader.getUint16();
  }
}

class StandardSpeedDataBlock extends DataBlock {
  StandardSpeedDataBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    //_tailMs =
        reader.getUint16();
    super._loadData(reader);
  }
}

class TextDescriptionBlock extends BlockBase {
  String description;

  TextDescriptionBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    description = String.fromCharCodes(reader.getUint8List(length));
  }
}

class MessageBlock extends BlockBase {
  int durationSec;
  String message;

  MessageBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    durationSec = reader.getUint8();
    var length = reader.getUint8();
    message = String.fromCharCodes(reader.getUint8List(length));
  }
}

class TurboSpeedDataBlock extends StandardSpeedDataBlock {
  TurboSpeedDataBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _pilotPulseLen = reader.getUint16();
    _firstSyncLen = reader.getUint16();
    _secondSyncLen = reader.getUint16();
    _zeroLen = reader.getUint16();
    _oneLen = reader.getUint16();
    _pilotLen = reader.getUint16();
    _rem = reader.getUint8();
    //_tailMs =
        reader.getUint16();
    var bytes = reader.getUint8List(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.getUint8List(length);
  }
}
