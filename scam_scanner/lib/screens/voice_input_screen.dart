// ============================================================
// lib/screens/voice_input_screen.dart
// ============================================================
// Hold-to-talk voice recording → STT transcription → Gemini.
// Uses the speech_to_text package (device's built-in engine).
// ============================================================

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import 'result_screen.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isAnalyzing = false;
  String _transcribedText = '';
  String _statusMessage = 'Hold the microphone button to record';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _statusMessage = '❌ Microphone permission denied. Please enable in Settings.');
      return;
    }

    final available = await _speech.initialize(
      onError: (error) => setState(() {
        _isListening = false;
        _statusMessage = 'Speech error: ${error.errorMsg}';
        _pulseController.stop();
      }),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );
    setState(() {
      _speechAvailable = available;
      if (!available) _statusMessage = '❌ Speech recognition not available on this device.';
    });
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    setState(() {
      _isListening = true;
      _transcribedText = '';
      _statusMessage = '🎙️ Listening... speak now';
    });
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _transcribedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_MY', // Malaysian English
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
      _statusMessage = _transcribedText.isNotEmpty
          ? '✅ Recording complete! Tap "Scan for Scam" to analyze.'
          : 'Hold the microphone button to record';
    });
  }

  Future<void> _analyze() async {
    if (_transcribedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a voice note first!', style: TextStyle(fontSize: 18))),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _geminiService.analyzeText(_transcribedText);

      await _firebaseService.logScamAnalysis(
        originalText: _transcribedText,
        geminiClassification: result.classification,
        fullResponse: result.fullResponse,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(originalText: _transcribedText, result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e', style: const TextStyle(fontSize: 18)), backgroundColor: Colors.red.shade800),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Record Voice Note', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      // Pin the scan button at the bottom so it never overflows
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SizedBox(
            height: 70,
            child: ElevatedButton.icon(
              onPressed: (_isAnalyzing || _transcribedText.isEmpty) ? null : _analyze,
              icon: _isAnalyzing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.search_rounded, size: 30),
              label: Text(
                _isAnalyzing ? 'AI is analyzing...' : 'Scan for Scam 🔍',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status Message ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A4A6A)),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // ── Hold-to-Talk Mic Button ──
              Center(
                child: GestureDetector(
                  onLongPressStart: (_) => _startListening(),
                  onLongPressEnd: (_) => _stopListening(),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFF2ECC71),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71)).withAlpha(100),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isListening ? 'Release to stop' : 'Hold to record',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isListening ? const Color(0xFFE74C3C) : Colors.white54,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // ── Transcription Preview ──
              if (_transcribedText.isNotEmpty) ...[
                const Text(
                  '🗣️ What you said:',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                  ),
                  child: Text(
                    _transcribedText,
                    style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                // Re-record button
                TextButton.icon(
                  onPressed: () => setState(() { _transcribedText = ''; _statusMessage = 'Hold the microphone button to record'; }),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
                  label: const Text('Re-record', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ),
                const SizedBox(height: 8),
              ],

            ],
          ),
        ),
      ),
    );
  }
}
