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
      'You MUST respond in BOTH English AND Bahasa Malaysia every time — this is mandatory.\n'
      'FORMAT YOUR RESPONSE EXACTLY LIKE THIS (do not skip any line):\n'
      '1. Start with EXACTLY one of: "High Risk:" / "Medium Risk:" / "Low Risk:"\n'
      '2. Next line: "Scam Type: [Parcel Scam / Bank Scam / Love Scam / Investment Fraud / Job Scam / Unknown]"\n'
      '3. 🇬🇧 English: Briefly explain the red flags and give immediate advice (2 sentences).\n'
      '4. 🇲🇾 Bahasa Malaysia: WAJIB tulis ringkasan risiko dan nasihat dalam Bahasa Malaysia (2 ayat).\n'
      'Keep total response under 100 words. Never skip the Bahasa Malaysia section.';

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
