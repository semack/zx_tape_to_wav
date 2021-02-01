import 'package:flutter_test/flutter_test.dart';
import 'package:zx_tape_to_wav/zx_tape_to_wav.dart';

void main() async {
  test('adds one to input values', () async {
    var tape = await ZxTape.createFromFile('test/test.tap');
    await tape.saveToWavFile('test/test.wav');
  });
}
