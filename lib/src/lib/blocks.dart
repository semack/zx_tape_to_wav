import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

abstract class BlockBase {
  int _index = -1;

  int get index => _index;

  BlockBase(int index, ReadBuffer reader) {
    _index = index;
    _loadData(reader);
  }

  void _loadData(ReadBuffer reader);
}

// tap block
class DataBlock extends BlockBase {
  DataBlock(int index, ReadBuffer reader) : super(index, reader);

  int _pilotPulseLen = 2168;

  int get pilotPulseLen => _pilotPulseLen;
  int _firstSyncLen = 667;

  int get firstSyncLen => _firstSyncLen;
  int _secondSyncLen = 735;

  int get secondSyncLen => _secondSyncLen;
  int _zeroLen = 855;

  int get zeroLen => _zeroLen;
  int _oneLen = 1710;

  int get oneLen => _oneLen;
  int _tailMs = 1000;

  int get tailMs => _tailMs;
  int _rem = 8;

  int get rem => _rem;
  int _pilotLen = 8083;

  int get pilotLen => _pilotLen;
  Uint8List _data = Uint8List(0);

  Uint8List get data => _data;

  bool get isCheckSumValid {
    int sum = 0;
    for (int i = 0; i < data.length - 1; i++) sum ^= data[i];
    return data[data.length - 1] == sum;
  }

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint16();
    _data = reader.getUint8List(length);
    if (_data[0] >= 128) _pilotLen = 3223;
  }
}

// 0x10:
class StandardSpeedDataBlock extends DataBlock {
  StandardSpeedDataBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var tailMs = reader.getUint16();
    super._loadData(reader);
    _tailMs = tailMs;
  }
}

// 0x11
class TurboSpeedDataBlock extends DataBlock {
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
    _tailMs = reader.getUint16();
    var bytes = reader.getUint8List(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.getUint8List(length);
  }
}

// 0x12
class PureToneBlock extends BlockBase {
  int _pulseLen = 0;
  int _pulses = 0;

  int get pulseLen => _pulseLen;

  int get pulses => _pulses;

  PureToneBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _pulseLen = reader.getUint16();
    _pulses = reader.getUint16();
  }
}

// 0x13
class PulseSequenceBlock extends BlockBase {
  Uint16List _pulses = Uint16List(0);

  Uint16List get pulses => _pulses;

  PulseSequenceBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    _pulses = Uint16List(length);
    for (var i = 0; i < length; i++) _pulses[i] = reader.getUint16();
  }
}

// 0x14
class PureDataBlock extends DataBlock {
  PureDataBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  bool get isCheckSumValid => true;

  @override
  void _loadData(ReadBuffer reader) {
    _zeroLen = reader.getUint16();
    _oneLen = reader.getUint16();
    _rem = reader.getUint8();
    _tailMs = reader.getUint16();
    var bytes = reader.getUint8List(3);
    var length = (bytes[2] << 16) + (bytes[1] << 8) + bytes[0];
    _data = reader.getUint8List(length);
    _pilotPulseLen = 0;
    _firstSyncLen = 0;
    _secondSyncLen = 0;
  }
}

// 0x19
class SymDef {
  final int t;
  final List<int> d;

  SymDef(this.t, this.d);
}

class BitReader {
  final ReadBuffer src;
  int bitPos = -1;
  int data = 0;

  BitReader(this.src);

  int read() {
    if (bitPos < 0) {
      data = src.getUint8();
      bitPos = 7;
    }
    var v = data & (1 << bitPos);
    bitPos--;
    if (v != 0) v = 1;
    return v;
  }

  int readBits(int bits) {
    int v = 0;
    int i = 0;

    while (i < bits) {
      v <<= 1;
      v |= read();
      i++;
    }
    return v;
  }
}

class GeneralizedDataBlock extends BlockBase {
  List<SymDef> get data => _data;
  var _data = <SymDef>[];
  var _tailMs = 0;

  int get tailMs => _tailMs;

  GeneralizedDataBlock(int index, ReadBuffer reader) : super(index, reader);

  List<SymDef> readSymDefs(ReadBuffer reader, int c, int p) {
    var result = <SymDef>[];

    for (var i = 0; i < c; i++) {
      var t = reader.getUint8();

      var d = <int>[];
      for (var i = 0; i < p; i++) d.add(reader.getUint16());

      // var d = reader.getUint16List(p);
      var s = SymDef(t, d);
      result.add(s);
    }
    return result;
  }

  @override
  void _loadData(ReadBuffer reader) {
    var totalBlockLength = reader.getUint32();
    _tailMs = reader.getUint16();

    var totp = reader.getUint32();
    var npp = reader.getUint8();
    var rb = reader.getUint8();
    var asp = rb;
    if (asp == 0) asp = 256;

    var totd = reader.getUint32();
    var npd = reader.getUint8();
    rb = reader.getUint8();
    var asd = rb;
    if (asd == 0) asd = 256;

    var pd = <SymDef>[];

    if (totp != 0) {
      var syms = readSymDefs(reader, asp, npp);

      for (var i = 0; i < totp; i++) {
        var symnum = reader.getUint8();
        var symcnt = reader.getUint16();
        while (symcnt > 0) {
          pd.add(syms[symnum]);
          symcnt--;
        }
      }
    }

    if (totd != 0) {
      var syms = readSymDefs(reader, asd, npd);

      var nb = (log(asd) / log(2)).ceil();

      var rd = BitReader(reader);
      for (var i = 0; i < totd; i++) {
        var symnum = rd.readBits(nb);
        pd.add(syms[symnum]);
      }
    }
    _data = pd;
  }
}

// 0x20, 0x2A
class PauseOrStopTheTapeBlock extends BlockBase {
  var _duration;

  int get duration => _duration;

  PauseOrStopTheTapeBlock(int index, ReadBuffer reader, {int duration = 0})
      : super(index, reader) {
    _duration = duration;
    _loadData(reader);
  }

  @override
  void _loadData(ReadBuffer reader) {
    if (_duration == 0) _duration = reader.getUint16();
  }
}

// 0x21
class GroupStartBlock extends BlockBase {
  String? _groupName;

  String? get groupName => _groupName;

  GroupStartBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    _groupName = String.fromCharCodes(reader.getUint8List(length));
  }
}

// 0x22
class GroupEndBlock extends BlockBase {
  @override
  void _loadData(ReadBuffer reader) {
    // nothing to do
  }

  GroupEndBlock(int index, ReadBuffer reader) : super(index, reader);
}

// 0x23
class JumpToBlock extends BlockBase {
  int _offset = 0;

  int get offset => _offset;

  JumpToBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _offset = reader.getUint16();
  }
}

// 0x24
class LoopStartBlock extends BlockBase {
  int _repetitions = 0;

  int get repetitions => _repetitions;

  LoopStartBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _repetitions = reader.getUint16();
  }
}

// 0x25
class LoopEndBlock extends BlockBase {
  @override
  void _loadData(ReadBuffer reader) {
    // nothing to do
  }

  LoopEndBlock(int index, ReadBuffer reader) : super(index, reader);
}

// 0x28
class SelectInfo {
  final int offset;
  final String description;

  SelectInfo(this.offset, this.description);
}

class SelectBlock extends BlockBase {
  Iterable<SelectInfo> get selectInfo => _selectInfo;
  List<SelectInfo> _selectInfo = [];

  @override
  void _loadData(ReadBuffer? reader) {
    reader!.getUint16(); // skip length
    var count = reader.getUint8();
    for (int i = 0; i < count; i++) {
      var offset = reader.getUint16();
      var len = reader.getUint8();
      var description = String.fromCharCodes(reader.getUint8List(len));
      var info = new SelectInfo(offset, description);
      _selectInfo.add(info);
    }
  }

  SelectBlock(int index, ReadBuffer reader) : super(index, reader);
}

// 0x30
class TextDescriptionBlock extends BlockBase {
  String? _description;

  String? get description => _description;

  TextDescriptionBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    var length = reader.getUint8();
    _description = String.fromCharCodes(reader.getUint8List(length));
  }
}

// 0x31
class MessageBlock extends BlockBase {
  int _durationSec = 0;
  String? _message;

  int get durationSec => _durationSec;

  String? get message => _message;

  MessageBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _durationSec = reader.getUint8();
    var length = reader.getUint8();
    _message = String.fromCharCodes(reader.getUint8List(length));
  }
}

// 0x32
class ArchiveInfoBlock extends BlockBase {
  String? _description;

  String? get description => _description;

  ArchiveInfoBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    {
      var length = reader.getUint16();
      _description = String.fromCharCodes(reader.getUint8List(length));
    }
  }
}

// 0x33
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

// 0x35
class CustomInfoBlock extends BlockBase {
  Uint8List _info = Uint8List(0);

  Uint8List get info => _info;
  String? _identification;

  String? get identification => _identification;

  CustomInfoBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    _identification = String.fromCharCodes(reader.getUint8List(16));
    var length = reader.getUint32();
    _info = reader.getUint8List(length);
  }
}

// 0x5A
class GlueBlock extends BlockBase {
  GlueBlock(int index, ReadBuffer reader) : super(index, reader);

  @override
  void _loadData(ReadBuffer reader) {
    reader.getUint8List(9);
  }
}
