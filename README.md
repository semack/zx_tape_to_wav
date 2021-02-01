# zx_tape_to_wav  [![License Apache 2.0](https://img.shields.io/badge/license-Apache%20License%202.0-green.svg)](http://www.apache.org/licenses/LICENSE-2.0)

Easy library to convert [.TAP](http://fileformats.archiveteam.org/wiki/TAP_(ZX_Spectrum)) / [.TZX](http://fileformats.archiveteam.org/wiki/TZX) files (a data format for ZX-Spectrum emulator) into [sound WAV file](https://en.wikipedia.org/wiki/WAV).

### Example of usage
```dart
    var tape = await ZxTape.createFromFile('roms/RENEGADE.tzx');
    await tape.saveToWavFile('output/RENEGADE.wav');
```

## License
Please see [LICENSE](LICENSE).

## Contribute
Contributions are welcome. Just open an Issue or submit a PR. 

## Contact
You can reach me via my [email](mailto://semack@gmail.com).

## Thanks
Many thanks especially to [Igor Maznitsa](https://github.com/raydac) for his [library](https://github.com/raydac/zxtap-to-wav) as a source for ideas.



