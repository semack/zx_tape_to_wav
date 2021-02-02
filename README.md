# zx_tape_to_wav  [![License Apache 2.0](https://img.shields.io/badge/license-Apache%20License%202.0-green.svg)](https://www.apache.org/licenses/LICENSE-2.0) ![Publish to PUB.DEV](https://github.com/semack/zx_tape_to_wav/workflows/Publish%20to%20PUB.DEV/badge.svg?branch=master)

Easy Flutter library to convert [.TAP/.TZX](https://documentation.help/BASin/format_tape.html) files (a data format for ZX-Spectrum emulator) into [sound WAV file](https://en.wikipedia.org/wiki/WAV).

### Usage
A simple usage example:
```dart
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
```

## Contribute
Contributions are welcome. Just open an Issue or submit a PR. 

## Contact
You can reach me via my [email](mailto://semack@gmail.com).

## Thanks
Many thanks especially to [Igor Maznitsa](https://github.com/raydac) for his [library](https://github.com/raydac/zxtap-to-wav) as a source for ideas.



