import 'binary_writer.dart';

class LowPassWriter extends BinaryWriter {
  final double smoothing;
  int _value;
  bool _first;

  LowPassWriter(bytes, int value, {bool first = true, this.smoothing = 5}) {
    _first = first;
    _value = value;
  }

  @override
  void writeSample(int sample) {
    if (_first) {
      bytes.add(sample);
      _first = false;
      _value = sample;
      return;
    }

    var currentValue = sample;
    _value += ((currentValue - _value) / smoothing).round();
    bytes.add(_value);
  }
}
