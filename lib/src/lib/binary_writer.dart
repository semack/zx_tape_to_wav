import 'dart:typed_data';

class BinaryWriter {
  var _bytes = new List<int>();

  Uint8List toBytes() => Uint8List.fromList(_bytes);

  void writeUint8(int byte, {Endian endian = Endian.little}) {
    _bytes.addAll(_numberAsByteList(byte, 2, endian));
  }

  void writeInt32(int byte, {Endian endian = Endian.little}) {
    _bytes.addAll(_numberAsByteList(byte, 4, endian));
  }

  void writeUint34(int byte, {Endian endian = Endian.little}) {
    _bytes.addAll(_numberAsByteList(byte, 4, endian));
  }

  static List<int> _numberAsByteList(int input, numBytes, endian) {
    var output = <int>[], curByte = input;
    for (var i = 0; i < numBytes; ++i) {
      output.insert(endian == Endian.big ? 0 : output.length, curByte & 255);
      curByte >>= 8;
    }
    return output;
  }
}
