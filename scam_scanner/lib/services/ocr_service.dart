// ============================================================
// lib/services/ocr_service.dart
// ============================================================
// Uses Google ML Kit (on-device) to extract text from images.
// No API key needed — runs fully offline.
// ============================================================

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    // Uses Latin-script recognition. Change to TextRecognitionScript.chinese
    // or .devanagari etc. for other languages if needed.
    script: TextRecognitionScript.latin,
  );

  /// Extracts all text from the given [imageFile] using on-device ML Kit OCR.
  /// Returns the extracted text as a single String.
  Future<String> extractTextFromImage(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);

    try {
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      // Join all text blocks into a single readable string
      final buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      final extracted = buffer.toString().trim();
      return extracted.isEmpty
          ? 'No readable text found in the image.'
          : extracted;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  /// Must be called when the service is no longer needed (e.g. widget dispose).
  void dispose() {
    _textRecognizer.close();
  }
}
