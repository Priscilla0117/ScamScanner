// ============================================================
// lib/services/firebase_service.dart
// ============================================================
// Platform-aware Firebase Auth: handles both mobile and web.
// Mobile: google_sign_in package + verifyPhoneNumber (Android/iOS)
// Web:    signInWithPopup + signInWithPhoneNumber (Chrome)
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // google_sign_in is only used on mobile; on web we use signInWithPopup
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Returns current authenticated user, or null if not logged in.
  User? get currentUser => _auth.currentUser;

  /// Stream that emits auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────────
  // Google Sign-In (platform-aware)
  // ─────────────────────────────────────────────

  /// On web: uses signInWithPopup (works in browser).
  /// On mobile: uses google_sign_in package (native OAuth).
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // ── Web: popup flow ──────────────────────
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      return await _auth.signInWithPopup(provider);
    } else {
      // ── Mobile: native google_sign_in flow ───
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in aborted by user.');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  // ─────────────────────────────────────────────
  // Phone OTP — Mobile (Android/iOS)
  // ─────────────────────────────────────────────

  /// Sends OTP via Firebase verifyPhoneNumber (Android/iOS only).
  /// NOT called on web — use [sendPhoneOtpWeb] instead.
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerified?.call(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Phone verification failed.');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Verifies the OTP [smsCode] against [verificationId] (mobile).
  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // ─────────────────────────────────────────────
  // Phone OTP — Web
  // ─────────────────────────────────────────────

  /// Sends OTP via signInWithPhoneNumber (web only).
  /// Returns a [ConfirmationResult] used to verify the code.
  Future<ConfirmationResult> sendPhoneOtpWeb(String phoneNumber) async {
    return await _auth.signInWithPhoneNumber(phoneNumber);
  }

  /// Verifies OTP code from web [ConfirmationResult].
  Future<UserCredential> verifyPhoneOtpWeb({
    required ConfirmationResult confirmationResult,
    required String smsCode,
  }) async {
    return await confirmationResult.confirm(smsCode);
  }

  // ─────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // Firestore: Scam Log
  // ─────────────────────────────────────────────

  /// Logs a scam analysis result to the `scam_logs` Firestore collection.
  Future<void> logScamAnalysis({
    required String originalText,
    required String geminiClassification,
    required String fullResponse,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('scam_logs').add({
        'userId': user.uid,
        'userEmail': user.email ?? user.phoneNumber ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'original_text': originalText.length > 500
            ? '${originalText.substring(0, 500)}...'
            : originalText,
        'gemini_classification': geminiClassification,
        'full_response': fullResponse,
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      debugPrint('Firestore logging error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Firestore: Fetch History
  // ─────────────────────────────────────────────

  /// Returns a stream of the current user's past scam scan logs,
  /// ordered newest-first. Used by the HistoryScreen.
  Stream<List<Map<String, dynamic>>> scamHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('scam_logs')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList())
        .handleError((e) {
          debugPrint('scamHistoryStream error (check Firestore rules): $e');
          return <Map<String, dynamic>>[];
        });
  }

  /// Returns a live stream of scam stats for the current user.
  /// Emits a map: { 'total': int, 'high': int }
  /// Used by the HomeScreen impact counter.
  Stream<Map<String, int>> scamStatsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({'total': 0, 'high': 0});

    return _firestore
        .collection('scam_logs')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      final high = docs
          .where((d) => d.data()['gemini_classification'] == 'High')
          .length;
      return {'total': docs.length, 'high': high};
    }).handleError((e) {
      debugPrint('scamStatsStream error (check Firestore rules): $e');
      return {'total': 0, 'high': 0};
    });
  }
}

