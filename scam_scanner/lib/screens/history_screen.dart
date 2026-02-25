// ============================================================
// lib/screens/history_screen.dart
// ============================================================
// Shows the user's past scam scan results from Firestore.
// Real-time stream — updates live as new scans come in.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // ── Risk color / icon helpers ────────────────────────────
  Color _badgeColor(String classification) {
    switch (classification) {
      case 'High':   return const Color(0xFFC0392B);
      case 'Medium': return const Color(0xFFD35400);
      default:       return const Color(0xFF1E8449);
    }
  }

  String _badgeEmoji(String classification) {
    switch (classification) {
      case 'High':   return '🚨';
      case 'Medium': return '⚠️';
      default:       return '✅';
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Just now';
    if (ts is Timestamp) {
      final dt = ts.toDate().toLocal();
      final date = '${dt.day}/${dt.month}/${dt.year}';
      final hour = dt.hour.toString().padLeft(2, '0');
      final min  = dt.minute.toString().padLeft(2, '0');
      return '$date  $hour:$min';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFFE74C3C), size: 28),
            SizedBox(width: 10),
            Text(
              'Scan History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.scamHistoryStream(),
        builder: (context, snapshot) {
          // ── Loading ──────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE74C3C)),
            );
          }

          // ── Error ────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load history.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty state ──────────────────────────────────
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_rounded, color: Colors.white24, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'No scans yet!',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your past scam checks will appear here.',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Stats banner ─────────────────────────────────
          final highCount   = items.where((i) => i['gemini_classification'] == 'High').length;
          final mediumCount = items.where((i) => i['gemini_classification'] == 'Medium').length;
          final lowCount    = items.where((i) => i['gemini_classification'] == 'Low').length;

          return Column(
            children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A4A6A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(label: 'Total', value: '${items.length}', color: Colors.white),
                    _StatChip(label: '🚨 High', value: '$highCount',   color: const Color(0xFFE74C3C)),
                    _StatChip(label: '⚠️ Med',  value: '$mediumCount', color: const Color(0xFFE67E22)),
                    _StatChip(label: '✅ Safe', value: '$lowCount',    color: const Color(0xFF2ECC71)),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item           = items[index];
                    final classification = item['gemini_classification'] as String? ?? 'Low';
                    final originalText   = item['original_text']        as String? ?? '';
                    final fullResponse   = item['full_response']        as String? ?? '';
                    final timestamp      = item['timestamp'];

                    return _HistoryCard(
                      index: index,
                      classification: classification,
                      emoji: _badgeEmoji(classification),
                      badgeColor: _badgeColor(classification),
                      originalText: originalText,
                      fullResponse: fullResponse,
                      timestamp: _formatTimestamp(timestamp),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats chip widget ─────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

// ── Individual history card ───────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final int index;
  final String classification;
  final String emoji;
  final Color badgeColor;
  final String originalText;
  final String fullResponse;
  final String timestamp;

  const _HistoryCard({
    required this.index,
    required this.classification,
    required this.emoji,
    required this.badgeColor,
    required this.originalText,
    required this.fullResponse,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withAlpha(120), width: 1.5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$classification Risk',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview of scanned text
              if (originalText.isNotEmpty)
                Text(
                  originalText.length > 80
                      ? '${originalText.substring(0, 80)}…'
                      : originalText,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        // Expanded: full AI response
        children: [
          const Divider(color: Color(0xFF4A4A6A)),
          if (fullResponse.isNotEmpty) ...[
            const Text(
              '🤖 AI Analysis',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              fullResponse,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          if (originalText.isNotEmpty) ...[
            const Text(
              '📋 Original Text',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              originalText,
              style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
