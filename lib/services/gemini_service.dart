// ============================================================
// lib/services/gemini_service.dart
// ============================================================
// Bilingual (EN + BM) Gemini analysis with scam type detection.
// Replace 'YOUR_GEMINI_API_KEY' with your key from:
// https://aistudio.google.com/app/apikey
// ============================================================

import 'package:google_generative_ai/google_generative_ai.dart';

// ── Result model returned by GeminiService ────────────────────
class GeminiResult {
  final String classification; // 'High', 'Medium', or 'Low'
  final String scamType;       // e.g. 'Bank Scam', 'Parcel Scam', etc.
  final String fullResponse;

  const GeminiResult({
    required this.classification,
    required this.scamType,
    required this.fullResponse,
  });
}

class GeminiService {
  // ⚠️ REPLACE WITH YOUR ACTUAL GEMINI API KEY
  static const String _apiKey = 'AIzaSyBz9tEo9Xbu1xEzxaTaeu5JKU4QNletEOg';

  // ── Bilingual system prompt ───────────────────────────────
  static const String _systemPrompt =
      'You are an empathetic AI assistant protecting elderly Malaysians from online scams. '
      'Analyze the text below and respond in BOTH English and Bahasa Malaysia.\n'
      'FORMAT YOUR RESPONSE EXACTLY LIKE THIS:\n'
      'Line 1: Start with EXACTLY one of: "High Risk:" / "Medium Risk:" / "Low Risk:"\n'
      'Line 2: Write "Scam Type: [Parcel Scam / Bank Scam / Love Scam / Investment Fraud / Job Scam / Unknown]"\n'
      'Line 3-4 (🇬🇧 English): Briefly explain the red flags and immediate advice.\n'
      'Line 5-6 (🇲🇾 Bahasa Malaysia): Ringkasan pendek dalam BM tentang risiko dan nasihat.\n'
      'Keep total response under 90 words.';

  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
        );

  /// Analyzes the given [text] for scam content.
  /// Returns a [GeminiResult] with classification, scam type, and full response.
  Future<GeminiResult> analyzeText(String text) async {
    if (text.trim().isEmpty) {
      return const GeminiResult(
        classification: 'Low',
        scamType: 'Unknown',
        fullResponse: 'Low Risk: No content provided to analyze.\nScam Type: Unknown\n\n'
            '🇬🇧 No suspicious content detected.\n'
            '🇲🇾 Tiada kandungan mencurigakan dikesan.',
      );
    }

    final prompt = '$_systemPrompt\n\nText to analyze:\n$text';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? 'Could not analyze. Please try again.';

      return GeminiResult(
        classification: _parseClassification(responseText),
        scamType: _parseScamType(responseText),
        fullResponse: responseText,
      );
    } catch (e) {
      throw Exception('Gemini API error: $e');
    }
  }

  // ── Parsers ───────────────────────────────────────────────

  /// Extracts 'High', 'Medium', or 'Low' from the response.
  String _parseClassification(String responseText) {
    final upper = responseText.toUpperCase();
    if (upper.startsWith('HIGH')) return 'High';
    if (upper.startsWith('MEDIUM')) return 'Medium';
    return 'Low';
  }

  /// Extracts the scam type from "Scam Type: ..." line.
  String _parseScamType(String responseText) {
    final match = RegExp(
      r'Scam Type:\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(responseText);
    if (match != null) {
      return match.group(1)?.trim() ?? 'Unknown';
    }
    return 'Unknown';
  }
}
