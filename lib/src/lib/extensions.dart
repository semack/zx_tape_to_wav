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

extension IntToLog2Extension on int {
  int log2() {
    var number = this;
    number |= number >> 1;
    number |= number >> 2;
    number |= number >> 4;
    number |= number >> 8;
    number |= number >> 16;
    number |= number >> 32;

    return _multiplyDeBruijnBitPosition[
        ((number - (number >> 1)) * 0x07EDD5E59A4E28C2) >> 58];
  }

  static List<int> _multiplyDeBruijnBitPosition = [
    63,
    0,
    58,
    1,
    59,
    47,
    53,
    2,
    60,
    39,
    48,
    27,
    54,
    33,
    42,
    3,
    61,
    51,
    37,
    40,
    49,
    18,
    28,
    20,
    55,
    30,
    34,
    11,
    43,
    14,
    22,
    4,
    62,
    57,
    46,
    52,
    38,
    26,
    32,
    41,
    50,
    36,
    17,
    19,
    29,
    10,
    13,
    21,
    56,
    45,
    25,
    31,
    35,
    16,
    9,
    12,
    44,
    24,
    15,
    8,
    23,
    7,
    6,
    5
  ];
}
