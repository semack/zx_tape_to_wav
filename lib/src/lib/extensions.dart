import 'dart:typed_data';

extension IntToByteListExtension on int {
  List<int> asByteList(numBytes, {Endian endian = Endian.little}) {
    var output = <int>[], curByte = this;
    for (var i = 0; i < numBytes; ++i) {
      output.insert(endian == Endian.big ? 0 : output.length, curByte & 255);
      curByte >>= 8;
    }
    return output;
  }
}
