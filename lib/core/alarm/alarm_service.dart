import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Aggressive fire alarm service that plays a loud programmatic siren
/// and vibrates the device continuously until manually stopped.
class AlarmService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _vibrationTimer;
  bool _isActive = false;
  bool soundEnabled = true;

  /// Whether the alarm is currently sounding.
  bool get isActive => _isActive;

  /// Trigger the fire alarm — loud siren + continuous vibration.
  Future<void> startAlarm({String severity = 'critical'}) async {
    if (_isActive) return;
    _isActive = true;

    // Keep screen on
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // Start vibration pattern: 500ms on, 200ms off, repeating
    _startVibration();

    // Play siren sound
    if (soundEnabled) {
      await _playSiren(severity);
    }
  }

  /// Stop the alarm — silence siren, stop vibration, release wakelock.
  Future<void> stopAlarm() async {
    if (!_isActive) return;
    _isActive = false;

    // Stop audio
    try {
      await _player.stop();
    } catch (_) {}

    // Stop vibration
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      Vibration.cancel();
    } catch (_) {}

    // Release wakelock
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  void _startVibration() {
    // Immediate first vibration
    _doVibrate();

    // Repeat every 700ms (500ms vibrate + 200ms pause)
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (_isActive) {
        _doVibrate();
      } else {
        _vibrationTimer?.cancel();
      }
    });
  }

  void _doVibrate() {
    try {
      Vibration.vibrate(duration: 500);
    } catch (_) {}
  }

  /// Generate and play a synthetic fire alarm siren.
  /// Uses a WAV file generated in-memory with alternating frequencies.
  Future<void> _playSiren(String severity) async {
    try {
      final wavBytes = _generateSirenWav(severity);

      // Set maximum volume
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.loop);

      await _player.play(BytesSource(wavBytes));
    } catch (e) {
      // Audio not available — alarm still vibrates
    }
  }

  /// Generate a WAV file in memory containing a fire alarm siren tone.
  /// Critical: fast alternating 880Hz/1100Hz. High: steady 660Hz pulse.
  Uint8List _generateSirenWav(String severity) {
    const sampleRate = 44100;
    const durationSeconds = 2; // Loop every 2 seconds
    const numSamples = sampleRate * durationSeconds;
    const numChannels = 1;
    const bitsPerSample = 16;
    const byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;

    final samples = Int16List(numSamples);

    if (severity == 'critical') {
      // Alternating siren: sweep between 600Hz and 1200Hz
      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;
        // Sweep frequency up and down over 0.5s periods
        final sweepPhase = (t % 0.5) / 0.5; // 0 to 1 over 0.5s
        final cycleHalf = ((t * 2).floor() % 2 == 0);
        final freq = cycleHalf
            ? 600.0 + 600.0 * sweepPhase  // 600 → 1200
            : 1200.0 - 600.0 * sweepPhase; // 1200 → 600

        // Square-ish wave for harsh alarm sound
        final sineVal = sin(2.0 * pi * freq * t);
        final shaped = sineVal > 0 ? 1.0 : -1.0;

        // Add slight envelope to avoid clicks
        final envelope = _pulseEnvelope(t, 0.15); // Pulse every 150ms

        samples[i] = (shaped * 16000 * envelope).toInt().clamp(-32768, 32767);
      }
    } else {
      // Warning tone: steady 660Hz with pulsing
      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;
        final sineVal = sin(2.0 * pi * 660.0 * t);

        // Pulse envelope: on for 300ms, off for 200ms
        final pulsePhase = (t % 0.5);
        final envelope = pulsePhase < 0.3 ? 1.0 : 0.0;

        samples[i] = (sineVal * 14000 * envelope).toInt().clamp(-32768, 32767);
      }
    }

    // Build WAV file
    final dataSize = numSamples * blockAlign;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57);  // W
    buffer.setUint8(9, 0x41);  // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little);  // PCM format
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataSize, Endian.little);

    // Write samples
    for (int i = 0; i < numSamples; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Pulsing envelope for harsh alarm effect.
  double _pulseEnvelope(double t, double period) {
    final phase = (t % period) / period;
    // Sharp on/off with tiny fade
    if (phase < 0.7) return 1.0;
    if (phase < 0.75) return 1.0 - (phase - 0.7) / 0.05;
    if (phase < 0.95) return 0.0;
    return (phase - 0.95) / 0.05;
  }

  void dispose() {
    stopAlarm();
    _player.dispose();
  }
}
