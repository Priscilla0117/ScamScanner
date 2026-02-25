// ============================================================
// lib/services/tts_service.dart
// ============================================================
// Text-to-Speech service using flutter_tts.
// Singleton pattern so TTS state is shared across screens.
// ============================================================

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // Singleton instance
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    await _flutterTts.setLanguage('en-MY'); // Malaysian English
    await _flutterTts.setSpeechRate(0.45);  // Slower for elderly users
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Voice selection: flutter_tts v4 auto-selects best available voice.
    // Slower speech rate (0.45) ensures clarity for elderly users.
  }

  /// Speak the given [text] aloud.
  Future<void> speak(String text) async {
    await _init();
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Dispose TTS engine resources.
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
