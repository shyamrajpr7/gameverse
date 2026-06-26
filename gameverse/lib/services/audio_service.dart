import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum SoundType {
  click,
  score,
  gameOver,
  achievement,
  jump,
  shoot,
  collect,
  swipe,
  notification,
}

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool _muted = false;
  bool _ready = false;
  final Map<SoundType, Uint8List> _cache = {};

  bool get isMuted => _muted;

  void setMuted(bool muted) {
    _muted = muted;
  }

  void toggleMute() => _muted = !_muted;

  Future<void> init() async {
    if (_ready) return;
    for (final type in SoundType.values) {
      _cache[type] = _generateWav(type);
    }
    _ready = true;
  }

  Future<void> play(SoundType type) async {
    if (_muted || !_ready) return;
    try {
      final bytes = _cache[type]!;
      final player = AudioPlayer();
      await player.setSource(BytesSource(bytes));
      unawaited(player.resume());
    } catch (_) {}
  }

  Uint8List _generateWav(SoundType type) {
    final sr = 22050;
    List<double> samples;

    switch (type) {
      case SoundType.click:
        samples = _generateTone(sr, 60, freq: 800, waveform: 'sine', volume: 0.25);
        break;
      case SoundType.score:
        samples = _generateSweep(sr, 200, 500, 1200, waveform: 'sine', volume: 0.2);
        break;
      case SoundType.gameOver:
        samples = _generateSweep(sr, 500, 500, 100, waveform: 'sine', volume: 0.25);
        break;
      case SoundType.achievement:
        samples = _generateAchievement(sr);
        break;
      case SoundType.jump:
        samples = _generateSweep(sr, 100, 300, 900, waveform: 'sine', volume: 0.2);
        break;
      case SoundType.shoot:
        samples = _generateSweep(sr, 80, 1200, 300, waveform: 'sawtooth', volume: 0.15);
        break;
      case SoundType.collect:
        samples = _generateTone(sr, 120, freq: 1400, waveform: 'sine', volume: 0.2, vibrato: 20);
        break;
      case SoundType.swipe:
        samples = _generateSweep(sr, 200, 200, 800, waveform: 'sine', volume: 0.12);
        break;
      case SoundType.notification:
        samples = _generateNotification(sr);
        break;
    }

    return _samplesToWav(samples, sr);
  }

  List<double> _generateTone(int sr, int durationMs,
      {required double freq,
      String waveform = 'sine',
      double volume = 0.3,
      double vibrato = 0}) {
    final n = (sr * durationMs / 1000).round();
    final result = <double>[];
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final progress = i / n;
      final env = _envelope(progress, 0.1, 0.15);
      final f = freq + sin(t * vibrato * 2 * pi) * 20;
      var v = _waveform(f * t, waveform);
      result.add(v * volume * env);
    }
    return result;
  }

  List<double> _generateSweep(int sr, int durationMs, double freqStart,
      double freqEnd,
      {String waveform = 'sine', double volume = 0.3}) {
    final n = (sr * durationMs / 1000).round();
    final result = <double>[];
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final progress = i / n;
      final env = _envelope(progress, 0.05, 0.2);
      final f = freqStart + (freqEnd - freqStart) * progress;
      var v = _waveform(f * t, waveform);
      result.add(v * volume * env);
    }
    return result;
  }

  List<double> _generateAchievement(int sr) {
    final notes = [523.0, 659.0, 523.0, 784.0];
    final noteLen = 120;
    final gapLen = 30;
    final result = <double>[];
    for (final note in notes) {
      final n = _generateTone(sr, noteLen, freq: note, volume: 0.2);
      result.addAll(n);
      final g = List.filled((sr * gapLen / 1000).round(), 0.0);
      result.addAll(g);
    }
    return result;
  }

  List<double> _generateNotification(int sr) {
    final a = _generateTone(sr, 120, freq: 800, volume: 0.18);
    final gap = List.filled((sr * 20 / 1000).round(), 0.0);
    final b = _generateTone(sr, 120, freq: 1200, volume: 0.18);
    return [...a, ...gap, ...b];
  }

  double _waveform(double phase, String type) {
    phase = phase - phase.floor();
    switch (type) {
      case 'square':
        return phase < 0.5 ? 1.0 : -1.0;
      case 'sawtooth':
        return 2.0 * phase - 1.0;
      case 'triangle':
        return 4.0 * (phase < 0.5 ? phase : 1.0 - phase) - 1.0;
      case 'sine':
      default:
        return sin(2 * pi * phase);
    }
  }

  double _envelope(double t, double attack, double release) {
    if (t < attack) return t / attack;
    if (t > 1.0 - release) return (1.0 - t) / release;
    return 1.0;
  }

  Uint8List _samplesToWav(List<double> samples, int sr) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final bytesPerSample = numChannels * bitsPerSample ~/ 8;
    final dataSize = samples.length * bytesPerSample;
    final fileSize = 36 + dataSize;
    final byteRate = sr * bytesPerSample;
    final blockAlign = numChannels * bitsPerSample ~/ 8;

    final wav = ByteData(44 + dataSize);
    int offset = 0;

    void w(String s) {
      for (int i = 0; i < s.length; i++) wav.setUint8(offset++, s.codeUnitAt(i));
    }
    void u32(int v) { wav.setUint32(offset, v, Endian.little); offset += 4; }
    void u16(int v) { wav.setUint16(offset, v, Endian.little); offset += 2; }

    w('RIFF');
    u32(fileSize);
    w('WAVE');
    w('fmt ');
    u32(16);
    u16(1);
    u16(numChannels);
    u32(sr);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    w('data');
    u32(dataSize);

    for (final s in samples) {
      final clamped = (s * 32767).clamp(-32767, 32767);
      final sample = clamped.round();
      wav.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return wav.buffer.asUint8List();
  }
}
