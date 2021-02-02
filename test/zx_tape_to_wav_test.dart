import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  test('test tap conversion', () async {
    await new File('test/test.tap').readAsBytes()
        .then((input) => ZxTape.create(input)
        .then((tape) => tape.toWavBytes(frequency:44100))
        .then((output) => new File('test/tap.wav').writeAsBytes(output)));
  });
  test('test tzx conversion', () async {
    await new File('test/test.tzx').readAsBytes()
        .then((input) => ZxTape.create(input)
        .then((tape) => tape.toWavBytes())
        .then((output) => new File('test/tzx.wav').writeAsBytes(output)));
  });
}
