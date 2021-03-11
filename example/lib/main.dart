import 'dart:io';

import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  await new File('assets/roms/test.tzx').readAsBytes().then((input) => ZxTape
          .create(input)
      .then((tape) => tape.toWavBytes(
          frequency: 22050,
          amplifySignal: true,
          progress: (percents) {
            print('progress => $percents');
          }))
      .then((output) => new File('assets/out/test.wav').writeAsBytes(output)));
}
