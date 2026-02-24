import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const ScamScannerApp());
}

class ScamScannerApp extends StatelessWidget {
  const ScamScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamScanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MultimodalScannerScreen(),
    );
  }
}

class MultimodalScannerScreen extends StatefulWidget {
  const MultimodalScannerScreen({super.key});

  @override
  State<MultimodalScannerScreen> createState() => _MultimodalScannerScreenState();
}

class _MultimodalScannerScreenState extends State<MultimodalScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  String _resultText = "Upload a screenshot or paste text to check for scams.";
  bool _isLoading = false;
  
  // Image handling variables
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // IMPORTANT: Paste your actual Gemini API Key here again!
  final String apiKey = 'AIzaSyDja0XZyafbgpIQky2zInU_2OJFp9bmO0E';

  // Function to open gallery and pick an image
  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _resultText = "Image selected! Click 'Check for Scams' to analyze.";
      });
    }
  }

  // Function to send data to Gemini
  Future<void> analyzeData() async {
    if (_textController.text.isEmpty && _imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _resultText = "AI is looking at your data...";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
      You are an expert Malaysian cybersecurity AI. 
      Look at this image and/or text. Does it contain signs of a scam? 
      Look for fake links, fake authorities (LHDN/PDRM), or high-pressure tactics.
      Reply EXACTLY in this format:
      [Probability]% Scam Risk. [1-2 sentence explanation].
      ''';

      late GenerateContentResponse response;

      if (_imageBytes != null) {
        // MULTIMODAL MODE: Send both Image and Text
        final imagePart = DataPart('image/jpeg', _imageBytes!);
        final textPart = TextPart("\nAdditional context: ${_textController.text}\n$prompt");
        
        response = await model.generateContent([
          Content.multi([textPart, imagePart])
        ]);
      } else {
        // TEXT ONLY MODE
        final content = [Content.text("Message: ${_textController.text}\n$prompt")];
        response = await model.generateContent(content);
      }

      setState(() {
        _resultText = response.text ?? "Could not analyze.";
        _isLoading = false;
      });
    } catch (e) {
      print("GEMINI ERROR: $e");
      setState(() {
        _resultText = "Error connecting to AI. Check your terminal.";
        _isLoading = false;
      });
    }
  }

  // Function to clear everything
  void resetScanner() {
    setState(() {
      _textController.clear();
      _imageBytes = null;
      _resultText = "Upload a screenshot or paste text to check for scams.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScamScanner AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetScanner,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Box
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Text("No image selected", style: TextStyle(color: Colors.grey)),
                    ),
            ),
            const SizedBox(height: 10),
            
            // Upload Image Button
            OutlinedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Upload Screenshot'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 20),

            // Text Input Box
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Or paste a suspicious link/message here...',
              ),
            ),
            const SizedBox(height: 20),

            // Check Button
            ElevatedButton(
              onPressed: _isLoading ? null : analyzeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Check for Scams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // Results Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}