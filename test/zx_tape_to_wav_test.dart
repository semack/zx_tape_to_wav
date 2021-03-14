import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  test('test tzx conversion', () async {
    await new File('example/assets/roms/test.tzx').readAsBytes().then((input) =>
        ZxTape.create(input)
            .then((tape) => tape.toWavBytes(
                boosted: true,
                frequency: 44100,
                progress: (percents) {
                  print('progress => $percents');
                }))
            .then((output) =>
                new File('example/assets/out/tzx.wav').writeAsBytes(output)));
  });
  test('test tap conversion', () async {
    await new File('example/assets/roms/test.tap').readAsBytes().then((input) =>
        ZxTape.create(input)
            .then((tape) => tape.toWavBytes(
                frequency: 44100,
                progress: (percents) {
                  print('progress => $percents');
                }))
            .then((output) =>
                new File('example/assets/out/tap.wav').writeAsBytes(output)));
  });
}
