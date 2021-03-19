class BinaryWriter {
  List<int> _bytes = <int>[];

  List<int> get bytes => _bytes;

  BinaryWriter();

  void writeSample(int sample) {
    var v8 = ((sample >> 8) + 128).round();
    _bytes.add(v8);
  }
}
