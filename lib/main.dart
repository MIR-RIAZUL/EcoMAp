import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Supabase configuration (reads .env / --dart-define / SharedPreferences)
  await SupabaseConfig.initialize();

  // Initialize Supabase SDK if valid credentials are configured
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: EchoMapApp(),
    ),
  );
}
