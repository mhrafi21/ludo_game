import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final _effects = AudioPlayer();
  final _music = AudioPlayer();
  bool _musicEnabled = false;

  Future<void> playDice() => _play([440, 660, 520]);
  Future<void> playMove() => _play([500]);
  Future<void> playCapture() => _play([300, 220]);
  Future<void> playVictory() => _play([523, 659, 784, 1047]);

  Future<void> _play(List<double> notes) async {
    await _effects.play(BytesSource(_wave(notes, noteDuration: .095)));
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) return;
    _musicEnabled = enabled;
    if (enabled) {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(.12);
      await _music
          .play(BytesSource(_wave([262, 330, 392, 330], noteDuration: .65)));
    } else {
      await _music.stop();
    }
  }

  Uint8List _wave(List<double> notes, {double noteDuration = .13}) {
    const sampleRate = 22050;
    const channels = 1;
    const bitsPerSample = 16;
    final samplesPerNote = (sampleRate * noteDuration).round();
    final sampleCount = samplesPerNote * notes.length;
    final bytes = Uint8List(44 + sampleCount * 2);
    final data = ByteData.sublistView(bytes);
    void writeText(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes[offset + i] = text.codeUnitAt(i);
      }
    }

    writeText(0, 'RIFF');
    data.setUint32(4, bytes.length - 8, Endian.little);
    writeText(8, 'WAVE');
    writeText(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(
        28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    data.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    writeText(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);
    for (var i = 0; i < sampleCount; i++) {
      final note = notes[i ~/ samplesPerNote];
      final withinNote = i % samplesPerNote;
      final envelope =
          min(1.0, withinNote / 500) * (1 - withinNote / samplesPerNote);
      final sample =
          sin(2 * pi * note * withinNote / sampleRate) * envelope * 10000;
      data.setInt16(44 + i * 2, sample.round(), Endian.little);
    }
    return bytes;
  }

  Future<void> dispose() async {
    await _effects.dispose();
    await _music.dispose();
  }
}
