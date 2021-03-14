abstract class BinaryWriter {
  List<int> _bytes;

  List<int> get bytes => _bytes;

  BinaryWriter() {
    _bytes = <int>[];
  }

  void writeSample(int sample) {
    var v8 = ((sample >> 8) + 128).round();
    _bytes.add(v8);
  }
}
