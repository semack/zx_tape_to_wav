import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class BinaryReader {
  ByteData get raw => _raw;
  ByteData _raw;
  ReadBuffer _reader;

  bool isEOF() => !_reader.hasRemaining;

  int readUint8() => _reader.getUint8();

  int readUint16() => _reader.getUint16();

  int readInt64() => _reader.getInt64();

  Uint8List readUint8Array(int length) => _reader.getUint8List(length);

  void skip(int length) => _reader.getUint8List(length);

  String readAsString(int length) =>
      new String.fromCharCodes(_reader.getUint8List(length));

  BinaryReader(ByteData data) {
    _raw = data;
    _reader = new ReadBuffer(data);
  }
}
