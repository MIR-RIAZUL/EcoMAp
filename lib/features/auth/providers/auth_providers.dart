import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

const String cloudBackupEnabledPrefKey = 'cloud_backup_enabled';

/// Base provider for SupabaseAuthService
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

/// Persisted state provider for whether Cloud Backup Mode is voluntarily enabled by the user.
/// Default: false (Local Mode is default, no login required)
class CloudBackupModeNotifier extends StateNotifier<bool> {
  CloudBackupModeNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(cloudBackupEnabledPrefKey) ?? false;
    } catch (_) {}
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(cloudBackupEnabledPrefKey, enabled);
    } catch (_) {}
  }
}

final cloudBackupEnabledProvider =
    StateNotifierProvider<CloudBackupModeNotifier, bool>((ref) {
  return CloudBackupModeNotifier();
});

/// Stream of Supabase authentication state changes
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Currently authenticated Supabase User (or null)
final currentUserProvider = Provider<User?>((ref) {
  // Watch stream to re-evaluate on auth state transitions
  ref.watch(authStateStreamProvider);
  final authService = ref.watch(supabaseAuthServiceProvider);
  return authService.currentUser;
});

/// Whether user is authenticated with Supabase
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Controller for auth actions with loading and error states
enum AuthActionState { idle, loading, success, error }

class AuthControllerState {
  final AuthActionState state;
  final String? errorMessage;
  final String? successMessage;

  const AuthControllerState({
    this.state = AuthActionState.idle,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => state == AuthActionState.loading;
}

class AuthController extends StateNotifier<AuthControllerState> {
  final SupabaseAuthService _authService;
  final Ref _ref;

  AuthController(this._authService, this._ref)
      : super(const AuthControllerState());

  void reset() {
    state = const AuthControllerState();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthControllerState(state: AuthActionState.loading);
    try {
      await _authService.signIn(email: email, password: password);
      // Automatically enable Cloud Backup Mode upon successful sign in
      await _ref.read(cloudBackupEnabledProvider.notifier).setEnabled(true);
      state = const AuthControllerState(
        state: AuthActionState.success,
        successMessage: 'Successfully signed in to EchoMap Cloud.',
      );
      return true;
    } catch (e) {
      state = AuthControllerState(
        state: AuthActionState.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = const AuthControllerState(state: AuthActionState.loading);
    try {
      final res = await _authService.signUp(email: email, password: password);
      await _ref.read(cloudBackupEnabledProvider.notifier).setEnabled(true);
      final confirmationNeeded = res.session == null;
      state = AuthControllerState(
        state: AuthActionState.success,
        successMessage: confirmationNeeded
            ? 'Account created! Please check your email inbox to confirm your account.'
            : 'Account created and signed in successfully.',
      );
      return true;
    } catch (e) {
      state = AuthControllerState(
        state: AuthActionState.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state = const AuthControllerState(state: AuthActionState.loading);
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AuthControllerState(
        state: AuthActionState.success,
        successMessage: 'Password reset link sent! Check your email.',
      );
      return true;
    } catch (e) {
      state = AuthControllerState(
        state: AuthActionState.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AuthControllerState(state: AuthActionState.loading);
    try {
      await _authService.signOut();
      // NOTE: Signing out never erases local memories!
      state = const AuthControllerState(state: AuthActionState.idle);
    } catch (e) {
      state = AuthControllerState(
        state: AuthActionState.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return AuthController(authService, ref);
});

