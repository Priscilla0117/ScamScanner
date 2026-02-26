// ============================================================
// lib/screens/home_screen.dart
// ============================================================
// Main hub screen with 3 large input method buttons.
// Accessible design for elderly users.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'text_input_screen.dart';
import 'image_input_screen.dart';
import 'voice_input_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late final String _displayName;

  @override
  void initState() {
    super.initState();
    final user = _firebaseService.currentUser;
    _displayName = user?.displayName ?? user?.phoneNumber ?? 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = _firebaseService;
    final displayName = _displayName;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFFE74C3C), size: 30),
            SizedBox(width: 10),
            Text(
              'ScamScanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70, size: 28),
            tooltip: 'Scan History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70, size: 28),
            tooltip: 'Sign Out',
            onPressed: () async {
              await firebaseService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Welcome Banner + Impact Counter ──
              StreamBuilder<Map<String, int>>(
                stream: firebaseService.scamStatsStream(),
                builder: (context, snap) {
                  final stats = snap.data ?? {'total': 0, 'high': 0};
                  final total = stats['total'] ?? 0;
                  final high  = stats['high']  ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4A4A6A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $displayName! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Received a suspicious message? Check it here!',
                          style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 16),
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF4A4A6A), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('🛡️ ', style: TextStyle(fontSize: 20)),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 15, height: 1.4),
                                    children: [
                                      TextSpan(
                                        text: 'Protected from $high scam${high == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: Color(0xFF2ECC71),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '  •  $total total check${total == 1 ? '' : 's'}',
                                        style: const TextStyle(color: Color(0xFF8899AA)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              const Text(
                'How do you want to check?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ── Button 1: Paste Text ──
              _InputOptionButton(
                icon: Icons.content_paste_rounded,
                iconColor: const Color(0xFF3498DB),
                backgroundColor: const Color(0xFF16213E),
                label: 'Paste Text Message',
                subtitle: 'Copy & paste a suspicious message or link',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TextInputScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // ── Button 2: Upload Screenshot ──
              _InputOptionButton(
                icon: Icons.image_search_rounded,
                iconColor: const Color(0xFFF39C12),
                backgroundColor: const Color(0xFF16213E),
                label: 'Upload Screenshot',
                subtitle: kIsWeb ? '⚠️ Requires Android app' : 'Photo of a WhatsApp/SMS scam message',
                onPressed: kIsWeb
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📱 OCR requires the Android app. Use "Paste Text" on web.', style: TextStyle(fontSize: 16)),
                            backgroundColor: Color(0xFFF39C12),
                            duration: Duration(seconds: 4),
                          ))
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ImageInputScreen())),
              ),
              const SizedBox(height: 16),

              // ── Button 3: Record Voice ──
              _InputOptionButton(
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFF2ECC71),
                backgroundColor: const Color(0xFF16213E),
                label: 'Record Voice Note',
                subtitle: kIsWeb ? '⚠️ Requires Android app' : 'Describe the suspicious call or message',
                onPressed: kIsWeb
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📱 Voice & STT require the Android app. Use "Paste Text" on web.', style: TextStyle(fontSize: 16)),
                            backgroundColor: Color(0xFF2ECC71),
                            duration: Duration(seconds: 4),
                          ))
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VoiceInputScreen())),
              ),

              const SizedBox(height: 24),

              // ── Footer tip ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460).withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF3498DB), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If in doubt, always call your family or police (999) first.',
                        style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large card button for each input option
class _InputOptionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  const _InputOptionButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4A4A6A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF8899AA), fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF4A4A6A), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
