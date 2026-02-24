import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
      home: const TextScannerScreen(),
    );
  }
}

class TextScannerScreen extends StatefulWidget {
  const TextScannerScreen({super.key});

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen> {
  final TextEditingController _textController = TextEditingController();
  String _resultText = "Enter a suspicious message or link above to check.";
  bool _isLoading = false;

  // IMPORTANT: Paste your actual Gemini API Key here
  final String apiKey = 'AIzaSyDja0XZyafbgpIQky2zInU_2OJFp9bmO0E';

  Future<void> analyzeText() async {
    final suspiciousText = _textController.text;
    if (suspiciousText.isEmpty) return;

    setState(() {
      _isLoading = true;
      
      _resultText = "Analyzing with Gemini...";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
      You are an expert Malaysian cybersecurity AI. Analyze this text/URL:
      "$suspiciousText"
      Determine the probability (0-100%) that this is a scam (e.g., phishing, fake APK, Macao scam).
      Reply EXACTLY in this format:
      [Probability]% Scam Risk. [1 sentence explanation].
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _resultText = response.text ?? "Could not analyze the text.";
        _isLoading = false;
      });
    } catch (e) {
      print("GEMINI ERROR: $e");
      setState(() {
        _resultText = "Error connecting to AI. Check your internet or API key.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScamScanner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Suspicious Message Checker',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste SMS, WhatsApp message, or URL here...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : analyzeText,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Check for Scams', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}