// ============================================================
// lib/screens/image_input_screen.dart
// ============================================================
// User uploads an image → OCR extracts text → Gemini analyzes.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import 'result_screen.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();

  XFile? _selectedImage;
  String _extractedText = '';
  bool _isExtracting = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    setState(() {
      _selectedImage = file;
      _extractedText = '';
      _isExtracting = true;
    });

    try {
      final text = await _ocrService.extractTextFromImage(file);
      setState(() {
        _extractedText = text;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Could not extract text: $e';
        _isExtracting = false;
      });
    }
  }

  Future<void> _analyze() async {
    if (_extractedText.isEmpty || _extractedText.startsWith('No readable text') || _extractedText.startsWith('Could not extract')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text found in image to analyze.', style: TextStyle(fontSize: 18))),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _geminiService.analyzeText(_extractedText);

      await _firebaseService.logScamAnalysis(
        originalText: _extractedText,
        geminiClassification: result.classification,
        fullResponse: result.fullResponse,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(originalText: _extractedText, result: result),
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
        title: const Text('Upload Screenshot', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image Preview ──
              GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4A4A6A), width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(_selectedImage!.path), fit: BoxFit.contain),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFF39C12), size: 60),
                            SizedBox(height: 12),
                            Text('Tap to select screenshot', style: TextStyle(color: Color(0xFF8899AA), fontSize: 20)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Pick Image Buttons ──
              Row(
                children: [
                  Expanded(
                    child: _PickButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Extracted Text Preview ──
              if (_isExtracting)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFFF39C12)),
                      SizedBox(height: 12),
                      Text('Reading text from image...', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                )
              else if (_extractedText.isNotEmpty) ...[
                const Text(
                  '📄 Text found in image:',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4A4A6A)),
                  ),
                  child: Text(
                    _extractedText,
                    style: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 17, height: 1.5),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Scan Button ──
                SizedBox(
                  height: 70,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyze,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 24, height: 24,
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
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _PickButton(icon: Icons.photo_library_rounded, label: 'Choose from Gallery', onPressed: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            const SizedBox(height: 12),
            _PickButton(icon: Icons.camera_alt_rounded, label: 'Take a Photo', onPressed: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _PickButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF39C12),
          side: const BorderSide(color: Color(0xFFF39C12), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
