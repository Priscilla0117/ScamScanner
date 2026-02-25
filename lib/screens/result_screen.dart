// ============================================================
// lib/screens/result_screen.dart
// ============================================================
// Displays scam analysis with:
//  • Risk level + scam type badges
//  • Bilingual AI explanation (EN + BM)
//  • Malaysian emergency hotlines (tap-to-call)
//  • Family Guardian WhatsApp alert button
//  • Auto-TTS readback
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String originalText;
  final GeminiResult result;

  const ResultScreen({
    super.key,
    required this.originalText,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();
  bool _isSpeaking = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakResult());
  }

  @override
  void dispose() {
    _tts.stop();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _speakResult() async {
    if (kIsWeb) return; // TTS not supported on web
    setState(() => _isSpeaking = true);
    await _tts.speak(widget.result.fullResponse);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _toggleSpeech() async {
    if (kIsWeb) return;
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _speakResult();
    }
  }

  // ── Risk colour scheme ──────────────────────────────────────
  Color get _bgColor {
    switch (widget.result.classification) {
      case 'High':   return const Color(0xFFC0392B);
      case 'Medium': return const Color(0xFFD35400);
      default:       return const Color(0xFF1E8449);
    }
  }

  Color get _accentColor {
    switch (widget.result.classification) {
      case 'High':   return const Color(0xFFFF6B6B);
      case 'Medium': return const Color(0xFFFFB347);
      default:       return const Color(0xFF2ECC71);
    }
  }

  String get _riskEmoji {
    switch (widget.result.classification) {
      case 'High':   return '🚨';
      case 'Medium': return '⚠️';
      default:       return '✅';
    }
  }

  String get _riskLabel {
    switch (widget.result.classification) {
      case 'High':   return 'HIGH RISK SCAM';
      case 'Medium': return 'MEDIUM RISK';
      default:       return 'LOW RISK';
    }
  }

  bool get _isHighOrMedium =>
      widget.result.classification == 'High' ||
      widget.result.classification == 'Medium';

  // ── Hotlines ────────────────────────────────────────────────
  Future<void> _callHotline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot dial $number on this device.')),
      );
    }
  }

  // ── Family Guardian alert ───────────────────────────────────
  Future<void> _showFamilyAlertDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('guardian_phone') ?? '';
    final controller = TextEditingController(text: savedPhone);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '📱 Alert Family / Guardian',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your family member\'s WhatsApp number\n(with country code, e.g. +60123456789)',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: '+60123456789',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4A4A6A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4A4A6A)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isEmpty || !phone.startsWith('+')) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number starting with +')),
                );
                return;
              }
              // Dismiss dialog first (before any await) to avoid BuildContext async gap
              Navigator.pop(ctx);
              await prefs.setString('guardian_phone', phone);
              if (mounted) await _sendWhatsAppAlert(phone);
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppAlert(String phone) async {
    final scamType = widget.result.scamType;
    final risk     = widget.result.classification;
    final preview  = widget.originalText.length > 100
        ? '${widget.originalText.substring(0, 100)}...'
        : widget.originalText;

    final message = Uri.encodeComponent(
      '🚨 *SCAM ALERT dari ScamScanner*\n\n'
      'Saya baru menerima mesej yang mencurigakan.\n'
      '⚠️ *Risiko: $risk Risk*\n'
      '🔍 *Jenis: $scamType*\n\n'
      '*Mesej yang dianalisis:*\n"$preview"\n\n'
      'Tolong bantu saya semak ini! / Please help me verify this!\n'
      '─ Dihantar melalui ScamScanner 🛡️',
    );

    // Try WhatsApp first, fall back to SMS
    final waUri   = Uri.parse('whatsapp://send?phone=$phone&text=$message');
    final smsUri  = Uri.parse('sms:$phone?body=${Uri.encodeComponent(widget.originalText.substring(0, widget.originalText.length.clamp(0, 160)))}');

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri);
    } else if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp not found. Please install WhatsApp and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (!kIsWeb)
                      IconButton(
                        icon: Icon(
                          _isSpeaking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
                        onPressed: _toggleSpeech,
                      ),
                  ],
                ),

                // ── Risk badge ──
                Center(
                  child: Column(
                    children: [
                      Text(_riskEmoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _riskLabel,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── Scam type pill ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          '🔍 ${widget.result.scamType}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── AI Explanation (bilingual) ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🤖 AI Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.result.fullResponse,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Malaysian Hotlines (High + Medium only) ──
                if (_isHighOrMedium) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📞 Emergency Hotlines Malaysia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HotlineRow(
                          emoji: '🚔',
                          label: 'PDRM (Police)',
                          number: '999',
                          onTap: () => _callHotline('999'),
                        ),
                        _HotlineRow(
                          emoji: '📡',
                          label: 'MCMC Scam Report',
                          number: '1-800-888-030',
                          onTap: () => _callHotline('1800888030'),
                        ),
                        _HotlineRow(
                          emoji: '🏦',
                          label: 'BNM Banking Scam',
                          number: '1-300-88-5465',
                          onTap: () => _callHotline('1300885465'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Family Alert button ──
                SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _showFamilyAlertDialog,
                    icon: const Icon(Icons.people_rounded, size: 26),
                    label: const Text(
                      'Alert Family / Guardian',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black38,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Original text collapse ──
                ExpansionTile(
                  title: const Text(
                    'View original text',
                    style: TextStyle(color: Colors.white70, fontSize: 17),
                  ),
                  iconColor: Colors.white70,
                  collapsedIconColor: Colors.white70,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.originalText,
                        style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Check Another ──
                SizedBox(
                  height: 68,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                    icon: const Icon(Icons.home_rounded, size: 28),
                    label: const Text(
                      'Check Another Message',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black38,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hotline row widget ────────────────────────────────────────
class _HotlineRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String number;
  final VoidCallback onTap;

  const _HotlineRow({
    required this.emoji,
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(number,
                      style: const TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
            const Icon(Icons.call_rounded, color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }
}
