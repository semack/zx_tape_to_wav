import 'dart:io';

import 'package:test/test.dart';
import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  test('test tzx conversion', () async {
    await new File('./test/assets/roms/RENEGATE.tzx').readAsBytes().then(
        (input) => ZxTape.create(input).then((tape) => tape.toWavBytes()).then(
            (output) => new File('./test/assets/out/RENEGATE-tzx.wav')
                .writeAsBytes(output)));
  });
  test('test tap conversion', () async {
    await new File('./test/assets/roms/RENEGATE.tap').readAsBytes().then(
        (input) => ZxTape.create(input)
            .then((tape) => tape.toWavBytes(frequency: 44100))
            .then((output) => new File('./test/assets/out/RENEGATE-tap.wav')
                .writeAsBytes(output)));
  });
}
