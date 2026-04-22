import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

class AuthService {
  static User? get currentUser => _sb.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStream => _sb.auth.onAuthStateChange;

  static const _webClientId =
      '818667313685-phdmniunn776scacsik3pgs0jh8evosv.apps.googleusercontent.com';
  static Future<AuthResponse> signUp(String email, String password) async {
    try {
      final res = await _sb.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: null, // optional (web only)
      );

      if (res.user == null) {
        throw Exception('Signup failed. Please try again.');
      }

      return res;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ── SIGN IN ─────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (res.session == null) {
        throw Exception('Invalid login credentials');
      }

      return res;
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ── SEND OTP (EMAIL VERIFICATION / MAGIC LINK STYLE) ─────
  static Future<void> sendOtp(String email) async {
    try {
      await _sb.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        emailRedirectTo: null,
      );
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // ── ERROR HANDLER ───────────────────────────────────────
  static String _handleError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('invalid login')) {
      return 'Invalid email or password';
    }
    if (msg.contains('user already registered')) {
      return 'User already exists';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email first';
    }

    return 'Something went wrong. Try again.';
  }

  // ── Password Reset (sends reset email) ────────────────────────────────────
  static Future<void> resetPassword(String email) =>
      _sb.auth.resetPasswordForEmail(email.trim().toLowerCase());

  static Future<AuthResponse> verifyOtp(String email, String token) =>
      _sb.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,
      );

  // ── Google Sign-In ────────────────────────────────────────────────────────

  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Google Sign-In: starting authenticate()');

      // Initialize with serverClientId before authenticate()
      await GoogleSignIn.instance.initialize(serverClientId: _webClientId);

      // Use authenticate() for version 7.x
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      debugPrint('🔵 Google account: ${googleUser.email}');

      // Get authentication - returns GoogleSignInAuthentication directly
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('🔵 idToken: ${idToken != null ? "found ✅" : "NULL ❌"}');

      if (idToken == null) {
        throw Exception(
          'No ID Token. Ensure Web Client ID is configured correctly.',
        );
      }

      // For accessToken in v7.x, we need to get it from authorizationClient
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email']);
        accessToken = authorization?.accessToken;
        debugPrint(
          '🔵 accessToken: ${accessToken != null ? "found ✅" : "NULL"}',
        );
      } catch (e) {
        debugPrint('🟡 Could not get access token: $e');
      }

      // Sign in to Supabase with Google tokens
      debugPrint('🔵 Signing in to Supabase...');
      final response = await _sb.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('✅ Supabase sign-in success: ${response.user?.email}');
      return response;
    } on GoogleSignInException catch (e) {
      debugPrint(' GoogleSignInException: ${e.code} - ${e.toString()}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint(' User cancelled — returning null');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in GoogleAuthService.signIn(): $e');
      rethrow;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _sb.auth.signOut();
  }

  // ── User helpers ──────────────────────────────────────────────────────────
  static String get userEmail => currentUser?.email ?? '';
  static String get userAvatarUrl =>
      (currentUser?.userMetadata?['avatar_url'] as String?) ?? '';
  static String get userName {
    final meta = currentUser?.userMetadata;
    return (meta?['full_name'] as String?) ??
        (meta?['name'] as String?) ??
        userEmail.split('@').firstOrNull ??
        'User';
  }

  static String get userInitials {
    final n = userName.trim().split(' ');
    return n.length >= 2
        ? '${n[0][0]}${n[1][0]}'.toUpperCase()
        : userName.substring(0, userName.length.clamp(0, 2)).toUpperCase();
  }
}
