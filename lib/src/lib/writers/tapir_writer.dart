// -----------------------------------------------------------------------------
//            This code based on the original code from
//   Tapir 1.0 (https://www.alessandrogrussu.it/tapir/index.html)
//                        written by Mikie.
// -----------------------------------------------------------------------------

import 'dart:math';

import '../definitions.dart';
import 'binary_writer.dart';

class TapirWriter extends BinaryWriter {
  static const double _scale = 4;
  static const double _r1 = 30000;
  static const double _r2 = 1680;
  static const double _r4_1 = 400;
  static const double _r4_0 = 1400;
  static const double _r5 = 8000;

  static const double _c2 = 100E-9;
  static const double _c3 = 10E-9;

  static const double _ucc = 5;

  static const _bpe_1 =
      1 / (_r2 * _c2) + (1 / _r1 + 1 / _r2 + 1 / _r4_1 + 1 / _r5) / _c3;
  static const _bpe_0 =
      1 / (_r2 * _c2) + (1 / _r1 + 1 / _r2 + 1 / _r4_0 + 1 / _r5) / _c3;

//400 ohm
  static const double _l1_1 = -329.09278654170789459;
  static const double _l2_1 = -4847.7751093943390815;
  static const double _l3_1 = -326465.98924692109588;

//1400 ohm
  static const double _l1_0 = -320.03611409086466826;
  static const double _l2_0 = -3485.9490113606652408;
  static const double _l3_0 = -149265.44344597704151;

  final int frequency;

  double _u1 = 0, _u2 = 0, _u3 = 0, _t = 0, _a = 0, _b = 0, _c = 0;
  bool _lvl = true;
  bool _seriesVal = false;
  int _seriesLen = 1;

  TapirWriter(this.frequency) {
    _a = -(_ucc * _r4_1 / (_r4_1 + _r5)) *
        ((1 / (_r2 * _c2 * _r2 * _c2) +
                    (1 / (_r2 * _c3) + _l2_1 + _l3_1) / (_r2 * _c2) +
                    _l2_1 * _l3_1) /
                ((_l1_1 - _l2_1) * (_l1_1 - _l3_1)) -
            ((_bpe_1 + _l2_1 + _l3_1) /
                (_r2 * _c2 * (_l1_1 - _l2_1) * (_l1_1 - _l3_1))) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l2_1) * (_l1_1 - _l3_1))));
    _b = -(_ucc * _r4_1 / (_r4_1 + _r5)) *
        ((1 / (_r2 * _c2 * _r2 * _c2) +
                    (1 / (_r2 * _c3) + _l1_1 + _l3_1) / (_r2 * _c2) +
                    _l1_1 * _l3_1) /
                ((_l1_1 - _l2_1) * (_l3_1 - _l2_1)) -
            ((_bpe_1 + _l1_1 + _l3_1) /
                (_r2 * _c2 * (_l1_1 - _l2_1) * (_l3_1 - _l2_1))) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l2_1) * (_l3_1 - _l2_1))));
    _c = -(_ucc * _r4_1 / (_r4_1 + _r5)) *
        ((1 / (_r2 * _c2 * _r2 * _c2) +
                    (1 / (_r2 * _c3) + _l1_1 + _l2_1) / (_r2 * _c2) +
                    _l1_1 * _l2_1) /
                ((_l1_1 - _l3_1) * (_l2_1 - _l3_1)) -
            ((_bpe_1 + _l1_1 + _l2_1) /
                (_r2 * _c2 * (_l1_1 - _l3_1) * (_l2_1 - _l3_1))) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l3_1) * (_l2_1 - _l3_1))));
  }

  setMic(bool level, double time) {
    _t += time;

    if (level != _lvl) {
      if (_lvl) {
        _u2 = _ucc * _r4_1 / (_r4_1 + _r5) +
            _a * exp(_l1_1 * _t) +
            _b * exp(_l2_1 * _t) +
            _c * exp(_l3_1 * _t);
        _u3 = _ucc * _r4_1 / (_r4_1 + _r5) +
            _a * (1 + _l1_1 * _r2 * _c2) * exp(_l1_1 * _t) +
            _b * (1 + _l2_1 * _r2 * _c2) * exp(_l2_1 * _t) +
            _c * (1 + _l3_1 * _r2 * _c2) * exp(_l3_1 * _t);
        _u1 = _ucc * _r4_1 / (_r4_1 + _r5) +
            _a *
                (_l1_1 * _l1_1 * _r2 * _c2 * _r1 * _c3 +
                    _l1_1 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_1 +
                    _r1 / _r5) *
                exp(_l1_1 * _t) +
            _b *
                (_l2_1 * _l2_1 * _r2 * _c2 * _r1 * _c3 +
                    _l2_1 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_1 +
                    _r1 / _r5) *
                exp(_l2_1 * _t) +
            _c *
                (_l3_1 * _l3_1 * _r2 * _c2 * _r1 * _c3 +
                    _l3_1 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_1 +
                    _r1 / _r5) *
                exp(_l3_1 * _t);
      } else {
        _u2 = _ucc * _r4_0 / (_r4_0 + _r5) +
            _a * exp(_l1_0 * _t) +
            _b * exp(_l2_0 * _t) +
            _c * exp(_l3_0 * _t);
        _u3 = _ucc * _r4_0 / (_r4_0 + _r5) +
            _a * (1 + _l1_0 * _r2 * _c2) * exp(_l1_0 * _t) +
            _b * (1 + _l2_0 * _r2 * _c2) * exp(_l2_0 * _t) +
            _c * (1 + _l3_0 * _r2 * _c2) * exp(_l3_0 * _t);
        _u1 = _ucc * _r4_0 / (_r4_0 + _r5) +
            _a *
                (_l1_0 * _l1_0 * _r2 * _c2 * _r1 * _c3 +
                    _l1_0 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_0 +
                    _r1 / _r5) *
                exp(_l1_0 * _t) +
            _b *
                (_l2_0 * _l2_0 * _r2 * _c2 * _r1 * _c3 +
                    _l2_0 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_0 +
                    _r1 / _r5) *
                exp(_l2_0 * _t) +
            _c *
                (_l3_0 * _l3_0 * _r2 * _c2 * _r1 * _c3 +
                    _l3_0 *
                        (_r1 * _c3 +
                            (_r1 + _r2 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                _c2) +
                    1 +
                    _r1 / _r4_0 +
                    _r1 / _r5) *
                exp(_l3_0 * _t);
      }

      _lvl = level;
      _t = 0;

      if (level) {
        _a = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l2_1 + _l3_1) / (_r2 * _c2) +
                        _l2_1 * _l3_1) /
                    ((_l1_1 - _l2_1) * (_l1_1 - _l3_1))) *
                (_u2 - _ucc * _r4_1 / (_r4_1 + _r5)) -
            ((_bpe_1 + _l2_1 + _l3_1) /
                    (_r2 * _c2 * (_l1_1 - _l2_1) * (_l1_1 - _l3_1))) *
                (_u3 - _ucc * _r4_1 / (_r4_1 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l2_1) * (_l1_1 - _l3_1))) *
                (_u1 - _ucc * _r4_1 / (_r4_1 + _r5));
        _b = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l1_1 + _l3_1) / (_r2 * _c2) +
                        _l1_1 * _l3_1) /
                    ((_l1_1 - _l2_1) * (_l3_1 - _l2_1))) *
                (_u2 - _ucc * _r4_1 / (_r4_1 + _r5)) -
            ((_bpe_1 + _l1_1 + _l3_1) /
                    (_r2 * _c2 * (_l1_1 - _l2_1) * (_l3_1 - _l2_1))) *
                (_u3 - _ucc * _r4_1 / (_r4_1 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l2_1) * (_l3_1 - _l2_1))) *
                (_u1 - _ucc * _r4_1 / (_r4_1 + _r5));
        _c = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l1_1 + _l2_1) / (_r2 * _c2) +
                        _l1_1 * _l2_1) /
                    ((_l1_1 - _l3_1) * (_l2_1 - _l3_1))) *
                (_u2 - _ucc * _r4_1 / (_r4_1 + _r5)) -
            ((_bpe_1 + _l1_1 + _l2_1) /
                    (_r2 * _c2 * (_l1_1 - _l3_1) * (_l2_1 - _l3_1))) *
                (_u3 - _ucc * _r4_1 / (_r4_1 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_1 - _l3_1) * (_l2_1 - _l3_1))) *
                (_u1 - _ucc * _r4_1 / (_r4_1 + _r5));
      } else {
        _a = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l2_0 + _l3_0) / (_r2 * _c2) +
                        _l2_0 * _l3_0) /
                    ((_l1_0 - _l2_0) * (_l1_0 - _l3_0))) *
                (_u2 - _ucc * _r4_0 / (_r4_0 + _r5)) -
            ((_bpe_0 + _l2_0 + _l3_0) /
                    (_r2 * _c2 * (_l1_0 - _l2_0) * (_l1_0 - _l3_0))) *
                (_u3 - _ucc * _r4_0 / (_r4_0 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_0 - _l2_0) * (_l1_0 - _l3_0))) *
                (_u1 - _ucc * _r4_0 / (_r4_0 + _r5));
        _b = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l1_0 + _l3_0) / (_r2 * _c2) +
                        _l1_0 * _l3_0) /
                    ((_l1_0 - _l2_0) * (_l3_0 - _l2_0))) *
                (_u2 - _ucc * _r4_0 / (_r4_0 + _r5)) -
            ((_bpe_0 + _l1_0 + _l3_0) /
                    (_r2 * _c2 * (_l1_0 - _l2_0) * (_l3_0 - _l2_0))) *
                (_u3 - _ucc * _r4_0 / (_r4_0 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_0 - _l2_0) * (_l3_0 - _l2_0))) *
                (_u1 - _ucc * _r4_0 / (_r4_0 + _r5));
        _c = ((1 / (_r2 * _c2 * _r2 * _c2) +
                        (1 / (_r2 * _c3) + _l1_0 + _l2_0) / (_r2 * _c2) +
                        _l1_0 * _l2_0) /
                    ((_l1_0 - _l3_0) * (_l2_0 - _l3_0))) *
                (_u2 - _ucc * _r4_0 / (_r4_0 + _r5)) -
            ((_bpe_0 + _l1_0 + _l2_0) /
                    (_r2 * _c2 * (_l1_0 - _l3_0) * (_l2_0 - _l3_0))) *
                (_u3 - _ucc * _r4_0 / (_r4_0 + _r5)) +
            (1 / (_r2 * _c2 * _r1 * _c3 * (_l1_0 - _l3_0) * (_l2_0 - _l3_0))) *
                (_u1 - _ucc * _r4_0 / (_r4_0 + _r5));
      }
    }
  }

  double micOut(double time) {
    if (_lvl) {
      return -_scale *
          (_a *
                  (_l1_1 * _l1_1 * _r2 * _c2 * _r1 * _c3 +
                      _l1_1 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_1 +
                      _r1 / _r5) *
                  exp(_l1_1 * (_t + time)) +
              _b *
                  (_l2_1 * _l2_1 * _r2 * _c2 * _r1 * _c3 +
                      _l2_1 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_1 +
                      _r1 / _r5) *
                  exp(_l2_1 * (_t + time)) +
              _c *
                  (_l3_1 * _l3_1 * _r2 * _c2 * _r1 * _c3 +
                      _l3_1 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_1 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_1 +
                      _r1 / _r5) *
                  exp(_l3_1 * (_t + time)));
    } else {
      return -_scale *
          (_a *
                  (_l1_0 * _l1_0 * _r2 * _c2 * _r1 * _c3 +
                      _l1_0 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_0 +
                      _r1 / _r5) *
                  exp(_l1_0 * (_t + time)) +
              _b *
                  (_l2_0 * _l2_0 * _r2 * _c2 * _r1 * _c3 +
                      _l2_0 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_0 +
                      _r1 / _r5) *
                  exp(_l2_0 * (_t + time)) +
              _c *
                  (_l3_0 * _l3_0 * _r2 * _c2 * _r1 * _c3 +
                      _l3_0 *
                          (_r1 * _c3 +
                              (_r1 + _r1 * _r2 / _r4_0 + _r1 * _r2 / _r5) *
                                  _c2) +
                      _r1 / _r4_0 +
                      _r1 / _r5) *
                  exp(_l3_0 * (_t + time)));
    }
  }

  @override
  void writeSample(int sample) {
    var bsv = sample == Definitions.signalValue;

    if (bsv == _seriesVal) {
      _seriesLen++;
      return;
    }

    _flush();

    _seriesVal = !_seriesVal;
    _seriesLen = 1;
  }

  void _flush() {
    var seriesDuration = _seriesLen / frequency;
    setMic(!_seriesVal, seriesDuration);

    for (var i = 0; i < _seriesLen; i++) {
      var s = micOut(i / frequency);
      if (s < -1) s = -1;
      if (s > 1) s = 1;
      var v = (s * Definitions.signalValue).round();
      super.writeSample(v);
    }
  }

  @override
  void flush() {
    _flush();
    super.flush();
  }
}
