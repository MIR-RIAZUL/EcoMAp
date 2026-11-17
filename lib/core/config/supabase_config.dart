import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure configuration loader for Supabase credentials.
/// Reads from compile-time environment flags (--dart-define),
/// optional local `.env` file, or user-configured SharedPreferences.
///
/// NOTE: Never configure or use a Supabase service_role or secret key here.
/// Only the public/anon key is allowed in client applications.
class SupabaseConfig {
  static const String _prefUrlKey = 'supabase_custom_url';
  static const String _prefAnonKey = 'supabase_custom_anon_key';

  // Compile-time environment variables:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const String envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String _activeUrl = '';
  static String _activeAnonKey = '';
  static bool _initialized = false;

  /// Current active Supabase URL
  static String get url => _activeUrl;

  /// Current active Supabase Anon Key (publishable key)
  static String get anonKey => _activeAnonKey;

  /// Returns true if valid Supabase credentials have been configured
  static bool get isConfigured =>
      _activeUrl.trim().isNotEmpty &&
      _activeAnonKey.trim().isNotEmpty &&
      !_activeUrl.contains('your-project-id');

  /// Initialize config from dart-define, local `.env` file, and SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;

    String resolvedUrl = envUrl.trim();
    String resolvedAnonKey = envAnonKey.trim();

    // If not supplied via --dart-define, attempt reading from local `.env` file
    if (resolvedUrl.isEmpty || resolvedAnonKey.isEmpty) {
      final envFile = File('.env');
      if (await envFile.exists()) {
        try {
          final lines = await envFile.readAsLines();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
            final eqIndex = trimmed.indexOf('=');
            if (eqIndex > 0) {
              final key = trimmed.substring(0, eqIndex).trim();
              final val = trimmed.substring(eqIndex + 1).trim();
              if (key == 'SUPABASE_URL' && resolvedUrl.isEmpty) {
                resolvedUrl = val;
              } else if (key == 'SUPABASE_ANON_KEY' && resolvedAnonKey.isEmpty) {
                resolvedAnonKey = val;
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading .env file: $e');
        }
      }
    }

    // Check if custom credentials were saved in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefUrlKey);
      final savedAnonKey = prefs.getString(_prefAnonKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        resolvedUrl = savedUrl;
      }
      if (savedAnonKey != null && savedAnonKey.isNotEmpty) {
        resolvedAnonKey = savedAnonKey;
      }
    } catch (_) {}

    _activeUrl = resolvedUrl;
    _activeAnonKey = resolvedAnonKey;
    _initialized = true;
  }

  /// Manually update credentials and persist to SharedPreferences
  static Future<void> saveCredentials({
    required String url,
    required String anonKey,
  }) async {
    _activeUrl = url.trim();
    _activeAnonKey = anonKey.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUrlKey, _activeUrl);
      await prefs.setString(_prefAnonKey, _activeAnonKey);
    } catch (e) {
      debugPrint('Failed to persist Supabase credentials: $e');
    }
  }

  /// Clear any custom credentials
  static Future<void> clearCustomCredentials() async {
    _activeUrl = envUrl.trim();
    _activeAnonKey = envAnonKey.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUrlKey);
      await prefs.remove(_prefAnonKey);
    } catch (_) {}
  }
}

