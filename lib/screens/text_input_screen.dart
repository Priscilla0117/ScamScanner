// ============================================================
// lib/screens/text_input_screen.dart
// ============================================================
// User pastes/types suspicious text, then sends it to Gemini.
// ============================================================

import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import 'result_screen.dart';

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste or type a message first!', style: TextStyle(fontSize: 18))),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _geminiService.analyzeText(text);

      // Log to Firestore (non-blocking)
      await _firebaseService.logScamAnalysis(
        originalText: text,
        geminiClassification: result.classification,
        fullResponse: result.fullResponse,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            originalText: text,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e', style: const TextStyle(fontSize: 18)),
          backgroundColor: Colors.red.shade800,
        ),
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
        title: const Text('Paste Text Message', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '📋 Paste or type the suspicious message below:',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // ── Text Input ──
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Paste suspicious message, link, or description here...',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                    filled: true,
                    fillColor: const Color(0xFF16213E),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A4A6A), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Clear Button ──
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _controller.clear()),
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    label: const Text('Clear', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ),
                ),

              // ── Scan Button ──
              SizedBox(
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Icon(Icons.search_rounded, size: 30),
                  label: Text(
                    _isAnalyzing ? 'AI is analyzing...' : 'Scan for Scam 🔍',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
