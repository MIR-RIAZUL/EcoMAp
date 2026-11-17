import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

/// Service handling Supabase authentication safely.
/// Preserves offline capabilities and provides clear, user-friendly error messages.
class SupabaseAuthService {
  final SupabaseClient? _client;

  SupabaseAuthService([SupabaseClient? client])
      : _client = client ?? (SupabaseConfig.isConfigured ? _safeGetClient() : null);

  static SupabaseClient? _safeGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Whether Supabase has been initialized with a valid client
  bool get isAvailable => _client != null;

  /// Currently authenticated user, or null if unauthenticated or in Local Mode
  User? get currentUser => _client?.auth.currentUser;

  /// ID of currently authenticated user, or null
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Email of currently authenticated user, or null
  String? get currentUserEmail => _client?.auth.currentUser?.email;

  /// Whether a user is currently signed in
  bool get isAuthenticated => currentUser != null;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) {
      return const Stream.empty();
    }
    return client.auth.onAuthStateChange;
  }

  /// Register a new account with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _ensureClientAvailable();
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Connection failed. Please check your internet and try again.');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _ensureClientAvailable();
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Connection failed. Please check your internet and try again.');
    }
  }

  /// Send password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    final client = _ensureClientAvailable();
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  /// Sign out the current user.
  /// NOTE: This only terminates the Supabase cloud session.
  /// Local Drift memories and photos are strictly preserved!
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut warning: $e');
    }
  }

  SupabaseClient _ensureClientAvailable() {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase is not configured yet. Please configure your Project URL and Publishable Key.',
      );
    }
    return client;
  }

  String _handleAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Invalid email or password. Please verify and try again.';
    } else if (message.contains('user already registered') ||
        message.contains('email already in use')) {
      return 'An account with this email already exists. Please sign in instead.';
    } else if (message.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    } else if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return e.message;
  }
}
