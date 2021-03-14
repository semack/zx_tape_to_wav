import 'dart:math';

import 'package:zx_tape_to_wav/src/lib/writers/binary_writer.dart';

class BassBoostWriter extends BinaryWriter {
  final int frequency;
  var _xn1 = 0.0;
  var _xn2 = 0.0;
  var _yn1 = 0.0;
  var _yn2 = 0.0;
  double _a0 = 0.0;
  double _a1 = 0.0;
  double _a2 = 0.0;
  double _b0 = 0.0;
  double _b1 = 0.0;
  double _b2 = 0.0;

  BassBoostWriter(this.frequency) {
    var bass = 20.0; // Bass gain (dB)

    // Pre init (like Audacity)
    var slope = 0.4;
    var hzBass = 250.0;

    // Calculate coefficients
    var ww = 2.0 * pi * hzBass / frequency;
    var a = exp(log(10.0) * bass / 40);
    var b = sqrt((a * a + 1) / slope - (pow(a - 1, 2)));

    _b0 = a * ((a + 1) - (a - 1) * cos(ww) + b * sin(ww));
    _b1 = 2 * a * ((a - 1) - (a + 1) * cos(ww));
    _b2 = a * ((a + 1) - (a - 1) * cos(ww) - b * sin(ww));
    _a0 = (a + 1) + (a - 1) * cos(ww) + b * sin(ww);
    _a1 = -2 * ((a - 1) + (a + 1) * cos(ww));
    _a2 = (a + 1) + (a - 1) * cos(ww) - b * sin(ww);
  }

  @override
  void writeSample(int sample) {
    var inp = sample / 32768.0;
    var out =
        (_b0 * inp + _b1 * _xn1 + _b2 * _xn2 - _a1 * _yn1 - _a2 * _yn2) / _a0;
    _xn2 = _xn1;
    _xn1 = inp;
    _yn2 = _yn1;
    _yn1 = out;

    if (out > 1) {
      out = 1;
    }
    if (out < -1) {
      out = -1;
    }
    var v = (out * 32767).round();
    super.writeSample(v);
  }
}
