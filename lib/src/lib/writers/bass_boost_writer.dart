import 'package:zx_tape_to_wav/src/lib/writers/binary_writer.dart';

class BassBoostWriter extends BinaryWriter {
  final int frequency;
  bool _first = true;
  int _previous = 0;
  int _last = 0;
  int _step = 0;
  int _pulseLen = 0;
  int _samplesThreshold1;
  int _samplesThreshold2;
  int _samplesThreshold3;
  int _samplesThreshold4;

  BassBoostWriter(this.frequency) {
    _samplesThreshold1 =
        (185.0E-6 * frequency).round(); // 185 mkSec, 8 @ 44.1kHz
    _samplesThreshold2 =
        (230.0E-6 * frequency).round(); // 230 mkSec, 10 @ 44.1kHz
    _samplesThreshold3 =
        (365.0E-6 * frequency).round(); // 365 mkSec, 16 @ 44.1kHz
    _samplesThreshold4 =
        (730.0E-6 * frequency).round(); // 730 mkSec, 32 @ 44.1kHz
  }

  @override
  void writeSample(int sample) {
    if (sample == 0) {
      sample = -32767;
    }

    if (_first) {
      _first = false;
      super.writeSample(sample);
      _previous = sample;
      return;
    }

    _pulseLen += 1;

    var delta = sample - _previous;

    var isRise = delta > 17000;
    var isFall = delta < -17000;

    var wp = _previous;
    _previous = sample;

    if (isRise) {
      if (_pulseLen > _samplesThreshold4) {
        // 32
        _last = wp;
      } else if (_pulseLen > _samplesThreshold3) {
        // 16
        _last = (wp + (delta / 2)).round();
      } else {
        _last = 0;
      }

      if (_pulseLen < _samplesThreshold1) {
        // 8
        _step = (delta / 8).round();
      } else {
        _step = (delta / 12).round();
      }
      super.writeSample(_last);
      _pulseLen = 0;
      return;
    }

    if (isFall && _pulseLen > _samplesThreshold2) {
      // 10
      _last = 0;
      _step = (delta / 12).round();
      super.writeSample(_last);
      _pulseLen = 0;
      return;
    }

    if (isFall) {
      _pulseLen = 0;
    }

    if (_step != 0) {
      _last += _step;

      if (_step > 0 && _last > sample) {
        _last = sample;
        _step = 0;
      }

      if (_step < 0 && _last < sample) {
        _last = sample;
        _step = 0;
      }
      super.writeSample(_last);
      return;
    }
    super.writeSample(sample);
  }
}
