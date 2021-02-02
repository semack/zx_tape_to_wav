import 'dart:io';

import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  var sourceFilePath = 'assets/roms/RENEGADE.tzx';
  var outputFileName = 'assets/out/RENEGADE.wav';
  await new File(sourceFilePath).readAsBytes().then((input) =>
      ZxTape.create(input)
          .then((tape) =>
              tape.toWavBytes(frequency: 44100, amplifySoundSignal: true))
          .then((output) => new File(outputFileName).writeAsBytes(output)));
}
