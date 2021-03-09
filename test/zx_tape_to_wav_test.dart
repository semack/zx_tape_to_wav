import 'dart:io';

import 'package:test/test.dart';
import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  test('test tzx conversion', () async {
    await new File('example/assets/roms/HoH.tzx').readAsBytes().then((input) =>
        ZxTape.create(input)
            .then((tape) => tape.toWavBytes(
                 frequency: 44100,
                progress: (percents) {
                  print(percents);
                }))
            .then((output) => new File('example/assets/out/RENEGATE-tzx1.wav')
                .writeAsBytes(output)));
  });
  // test('test tap conversion', () async {
  //   await new File('example/assets/roms/RENEGATE.tap').readAsBytes().then(
  //       (input) => ZxTape.create(input)
  //           .then((tape) => tape.toWavBytes(frequency: 44100, amplifySoundSignal: true))
  //           .then((output) => new File('example/assets/out/RENEGATE-tap.wav')
  //               .writeAsBytes(output)));
  // });
}
