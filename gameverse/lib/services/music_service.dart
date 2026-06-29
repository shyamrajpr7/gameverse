import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum MusicTrack {
  menu,
  action,
  calm,
  victory,
  silent,
}

class MusicService {
  static final MusicService _instance = MusicService._();
  factory MusicService() => _instance;
  MusicService._();

  AudioPlayer? _player;
  MusicTrack _currentTrack = MusicTrack.silent;
  double _volume = 0.35;
  bool _initialized = false;
  bool _muted = false;
  final Map<MusicTrack, Uint8List> _cache = {};
  Timer? _fadeTimer;

  double get volume => _volume;
  bool get isMuted => _muted;
  bool get isPlaying => _player?.state == PlayerState.playing;
  MusicTrack get currentTrack => _currentTrack;

  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      _player?.setVolume(0);
    } else {
      _player?.setVolume(_volume);
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (!_muted) {
      _player?.setVolume(_volume);
    }
  }

  void toggleMute() {
    setMuted(!_muted);
  }

  Future<void> init() async {
    if (_initialized) return;

    final sr = 22050;

    _cache[MusicTrack.menu] = _generateMenuTheme(sr);
    _cache[MusicTrack.action] = _generateActionTheme(sr);
    _cache[MusicTrack.calm] = _generateCalmTheme(sr);
    _cache[MusicTrack.victory] = _generateVictoryFanfare(sr);

    _player = AudioPlayer();
    _player!.onPlayerComplete.listen((_) {
      _restartTrack();
    });

    _initialized = true;
  }

  Future<void> play(MusicTrack track) async {
    if (!_initialized || _muted) return;

    if (track == _currentTrack && _player?.state == PlayerState.playing) return;
    if (track == MusicTrack.silent) {
      await stop();
      return;
    }

    final data = _cache[track];
    if (data == null) return;

    await _player?.stop();
    _currentTrack = track;
    await _player?.setSource(BytesSource(data));
    await _player?.setVolume(_volume);
    await _player?.resume();
  }

  Future<void> stop() async {
    _fadeTimer?.cancel();
    await _player?.stop();
    _currentTrack = MusicTrack.silent;
  }

  Future<void> dispose() async {
    _fadeTimer?.cancel();
    await _player?.dispose();
    _player = null;
    _initialized = false;
  }

  void _restartTrack() {
    if (_currentTrack != MusicTrack.silent && !_muted) {
      play(_currentTrack);
    }
  }

  double _envelope(double t, double attack, double release) {
    if (t < attack) return t / attack;
    if (t > 1.0 - release) return (1.0 - t) / release;
    return 1.0;
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
      for (int i = 0; i < s.length; i++) {
        wav.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    void u32(int v) {
      wav.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void u16(int v) {
      wav.setUint16(offset, v, Endian.little);
      offset += 2;
    }

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

  Uint8List _generateMenuTheme(int sr) {
    final bpm = 75;
    final beatsPerChord = 4;
    final chordCount = 4;
    final beatLen = (60.0 / bpm);
    final totalBeats = chordCount * beatsPerChord;
    final totalSamples = (totalBeats * beatLen * sr).round();

    final samples = Float64List(totalSamples);
    final chordFreqs = [
      [261.63, 329.63, 392.00, 523.25], // C major
      [220.00, 261.63, 329.63, 440.00], // A minor
      [174.61, 220.00, 261.63, 349.23], // F major
      [196.00, 246.94, 293.66, 392.00], // G major
    ];

    for (int c = 0; c < chordCount; c++) {
      final freqs = chordFreqs[c];
      final startSample = (c * beatsPerChord * beatLen * sr).round();
      final chordSamples = (beatsPerChord * beatLen * sr).round();

      for (int i = 0; i < chordSamples; i++) {
        final t = i / sr;
        final progress = i / chordSamples;
        final env = _envelope(progress, 0.08, 0.08);

        final lfo = 0.7 + 0.3 * sin(t * 0.3 * 2 * pi);

        double sample = 0;
        for (final freq in freqs) {
          final detune = 1.0 + (Random().nextDouble() - 0.5) * 0.002;
          final phase = freq * detune * t;
          sample += _waveform(phase, 'sawtooth') * 0.08;
          sample += _waveform(phase * 2, 'sine') * 0.04;
          sample += _waveform(phase * 0.5, 'sine') * 0.06;
        }

        final echo = (i >= sr ~/ 4)
            ? samples[startSample + i - sr ~/ 4] * 0.25
            : 0.0;

        final idx = startSample + i;
        if (idx < totalSamples) {
          samples[idx] = (sample * env * lfo + echo) * 0.35;
        }
      }
    }

    // crossfade loop points
    final fadeLen = (sr * 0.5).round();
    for (int i = 0; i < fadeLen; i++) {
      final fadeIn = i / fadeLen;
      final fadeOut = 1.0 - fadeIn;
      samples[i] *= fadeIn;
      samples[totalSamples - 1 - i] *= fadeOut;
    }

    return _samplesToWav(samples.toList(), sr);
  }

  Uint8List _generateActionTheme(int sr) {
    final bpm = 128;
    final beatLen = 60.0 / bpm;
    final totalBeats = 32;
    final totalSamples = (totalBeats * beatLen * sr).round();

    final samples = Float64List(totalSamples);
    final bassFreqs = [110.0, 130.81, 146.83, 164.81]; // A2, C3, D3, E3

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sr;
      final beat = (t / beatLen);
      final beatPhase = beat - beat.floor();
      final bar = (beat / 4).floor();
      final bassFreq = bassFreqs[bar % bassFreqs.length];

      double sample = 0;

      // Kick on beats 0 and 2
      if (beatPhase < 0.1 && (beat.floor() % 2 == 0)) {
        final kickT = beatPhase / 0.1;
        final kickFreq = 80 - 60 * kickT;
        sample += sin(2 * pi * kickFreq * t * 2) * 0.3 * (1 - kickT);
      }

      // Hi-hat on 8th notes
      if (beatPhase < 0.05) {
        sample += Random().nextDouble() * 0.08;
      }

      // Bass pulse
      final bassEnv = (beatPhase < 0.25) ? 1.0 - beatPhase / 0.25 : 0.0;
      final bassDetune = 1.0 + sin(t * 2 * pi * 0.1) * 0.003;
      sample += _waveform(bassFreq * bassDetune * t, 'square') * 0.15 * bassEnv;

      // Pad
      final padFreqs = [220.0, 261.63, 329.63, 392.00];
      final lfo = 0.8 + 0.2 * sin(t * 0.5 * 2 * pi);
      for (final f in padFreqs) {
        sample += _waveform(f * t, 'sawtooth') * 0.03 * lfo;
      }
      sample += _waveform(220.0 * t * 2, 'sine') * 0.02;

      final idx = i;
      if (idx < totalSamples) {
        samples[idx] = sample * 0.4;
      }
    }

    final fadeLen = (sr * 0.3).round();
    for (int i = 0; i < fadeLen; i++) {
      final fadeIn = i / fadeLen;
      final fadeOut = 1.0 - fadeIn;
      samples[i] *= fadeIn;
      samples[totalSamples - 1 - i] *= fadeOut;
    }

    return _samplesToWav(samples.toList(), sr);
  }

  Uint8List _generateCalmTheme(int sr) {
    final bpm = 65;
    final beatLen = 60.0 / bpm;
    final chordCount = 4;
    final beatsPerChord = 4;
    final totalBeats = chordCount * beatsPerChord;
    final totalSamples = (totalBeats * beatLen * sr).round();

    final samples = Float64List(totalSamples);
    final chordFreqs = [
      [392.00, 523.25, 659.25, 783.99], // G4 B5 E5 G5
      [440.00, 554.37, 659.25, 880.00], // A4 C#5 E5 A5
      [349.23, 440.00, 523.25, 698.46], // F4 A4 C5 F5
      [329.63, 415.30, 523.25, 659.25], // E4 G#4 B4 E5
    ];

    for (int c = 0; c < chordCount; c++) {
      final freqs = chordFreqs[c];
      final startSample = (c * beatsPerChord * beatLen * sr).round();
      final chordSamples = (beatsPerChord * beatLen * sr).round();

      for (int i = 0; i < chordSamples; i++) {
        final t = i / sr;
        final progress = i / chordSamples;
        final env = _envelope(progress, 0.1, 0.2);

        final lfo = 0.6 + 0.4 * sin(t * 0.2 * 2 * pi);

        double sample = 0;
        for (final freq in freqs) {
          sample += _waveform(freq * t, 'triangle') * 0.06;
          sample += _waveform(freq * 0.5 * t, 'sine') * 0.05;
        }
        sample += _waveform(freqs[0] * 0.25 * t, 'sine') * 0.04;

        final idx = startSample + i;
        if (idx < totalSamples) {
          samples[idx] = (sample * env * lfo) * 0.35;
        }
      }
    }

    final fadeLen = (sr * 0.8).round();
    for (int i = 0; i < fadeLen; i++) {
      final fadeIn = i / fadeLen;
      final fadeOut = 1.0 - fadeIn;
      samples[i] *= fadeIn;
      samples[totalSamples - 1 - i] *= fadeOut;
    }

    return _samplesToWav(samples.toList(), sr);
  }

  Uint8List _generateVictoryFanfare(int sr) {
    final noteLen = 0.2;
    final notes = [523.25, 659.25, 783.99, 1046.50];
    final totalSamples = (notes.length * noteLen * sr + sr).round();

    final samples = Float64List(totalSamples);

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final start = (n * noteLen * sr).round();
      final len = (noteLen * sr).round();

      for (int i = 0; i < len; i++) {
        final t = i / sr;
        final progress = i / len;
        final env = _envelope(progress, 0.01, 0.3);
        final idx = start + i;

        if (idx < totalSamples) {
          samples[idx] = _waveform(freq * t, 'sawtooth') * 0.15 * env;
          samples[idx] += _waveform(freq * t * 2, 'sine') * 0.08 * env;
          samples[idx] += _waveform(freq * t * 3, 'sine') * 0.04 * env;
        }
      }
    }

    // Tail
    for (int i = 0; i < sr; i++) {
      final t = i / sr;
      final fade = 1.0 - t;
      final idx = totalSamples - sr + i;
      if (idx < totalSamples) {
        samples[idx] = sin(2 * pi * 523.25 * (t + notes.length * noteLen)) *
            0.12 * fade * fade;
      }
    }

    return _samplesToWav(samples.toList(), sr);
  }
}
