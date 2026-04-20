import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _sb => Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
  AuthState copyWith({User? user, bool? isLoading, String? error}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
  AuthState loading() => AuthState(user: user, isLoading: true);
  AuthState withError(String e) => AuthState(user: user, error: e);
  AuthState loggedIn(User u) => AuthState(user: u, isLoading: false);
  AuthState loggedOut() => const AuthState();
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Keep state in sync with Supabase auth stream
    _sb.auth.onAuthStateChange.listen((event) {
      state = event.session?.user != null
          ? state.loggedIn(event.session!.user)
          : state.loggedOut();
    });
    return AuthState(user: _sb.auth.currentUser);
  }

  Future<String?> signUp(String email, String password) async {
    state = state.loading();
    try {
      final r = await _sb.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );
      state = r.user != null
          ? state.loggedIn(r.user!)
          : state.withError('Sign up failed');
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    state = state.loading();
    try {
      final r = await _sb.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      state = r.user != null
          ? state.loggedIn(r.user!)
          : state.withError('Sign in failed');
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  Future<void> sendOtp(String email) => _sb.auth.signInWithOtp(
    email: email.trim().toLowerCase(),
    shouldCreateUser: true,
  );

  Future<String?> verifyOtp(String email, String token) async {
    state = state.loading();
    try {
      final r = await _sb.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,
      );
      state = r.user != null
          ? state.loggedIn(r.user!)
          : state.withError('Invalid code');
      return null;
    } catch (e) {
      state = state.withError(e.toString());
      return e.toString();
    }
  }

  // Future<String?> signInWithGoogle() async {
  //   state = state.loading();
  //   try {
  //     final gAccount = await GoogleSignIn(
  //       clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  //     ).signIn();
  //     if (gAccount == null) {
  //       state = state.loggedOut();
  //       return 'Cancelled';
  //     }
  //     final gAuth = await gAccount.authentication;
  //     if (gAuth.idToken == null) throw Exception('No ID token');
  //     final r = await _sb.auth.signInWithIdToken(
  //       provider: OAuthProvider.google,
  //       idToken: gAuth.idToken!,
  //       accessToken: gAuth.accessToken,
  //     );
  //     state = r.user != null
  //         ? state.loggedIn(r.user!)
  //         : state.withError('Google sign in failed');
  //     return null;
  //   } catch (e) {
  //     state = state.withError(e.toString());
  //     return e.toString();
  //   }
  // }

  // Future<void> signOut() async {
  //   await GoogleSignIn().signOut().catchError((_) {});
  //   await _sb.auth.signOut();
  //   state = state.loggedOut();
  // }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ── Derived user info ─────────────────────────────────────────────────────────
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider).user,
);
final isLoggedInProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isLoggedIn,
);

final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'Guest';
  final meta = user.userMetadata;
  return (meta?['full_name'] as String?) ??
      (meta?['name'] as String?) ??
      user.email?.split('@').first ??
      'User';
});

final userInitialsProvider = Provider<String>((ref) {
  final name = ref.watch(userNameProvider);
  final parts = name.trim().split(' ');
  return parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
});

final userEmailProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.email ?? '',
);
final userAvatarProvider = Provider<String>(
  (ref) =>
      (ref.watch(currentUserProvider)?.userMetadata?['avatar_url']
          as String?) ??
      '',
);
