import 'dart:io';
import 'package:echomap/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  HttpOverrides.global = null;

  group('Update 6: Live Supabase Integration Verification', () {
    late String supabaseUrl;
    late String supabaseAnonKey;
    late bool hasCredentials;

    setUpAll(() async {
      await SupabaseConfig.initialize();
      supabaseUrl = SupabaseConfig.url;
      supabaseAnonKey = SupabaseConfig.anonKey;
      hasCredentials = SupabaseConfig.isConfigured;
    });

    test('1. Confirm .env configuration and URL normalization', () {
      expect(hasCredentials, isTrue,
          reason: 'Valid Supabase credentials must be present in .env');
      expect(supabaseUrl.startsWith('https://'), isTrue);
      expect(supabaseUrl.endsWith('/'), isFalse,
          reason: 'Supabase URL must not have trailing slashes');
      expect(supabaseUrl.endsWith('/rest/v1'), isFalse,
          reason: 'Supabase URL must not include /rest/v1 path');
      expect(supabaseAnonKey.isNotEmpty, isTrue);

      // Verify normalization logic
      expect(
        SupabaseConfig.normalizeUrl('https://example.supabase.co/rest/v1/'),
        equals('https://example.supabase.co'),
      );
      expect(
        SupabaseConfig.normalizeUrl('https://example.supabase.co///'),
        equals('https://example.supabase.co'),
      );
    });

    test('2. Live Project Connectivity & Row Level Security on public.memories', () async {
      if (!hasCredentials) return;

      final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

      // Verify that anonymous query returns empty (RLS restricted)
      final queryRes = await client.from('memories').select().limit(5);
      expect(queryRes, isEmpty,
          reason: 'RLS must hide memories from unauthenticated queries');

      // Verify that unauthenticated INSERT is strictly rejected with 42501 (RLS violation)
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      try {
        await client.from('memories').insert({
          'id': const Uuid().v4(),
          'user_id': const Uuid().v4(),
          'title': '[TEST] Unauthorized Attempt',
          'mood': 'neutral',
          'tags': 'test',
          'date_time': nowUtc,
          'created_at': nowUtc,
          'updated_at': nowUtc,
        });
        fail('Unauthenticated insert should have been rejected by RLS');
      } on PostgrestException catch (e) {
        expect(e.code, equals('42501'),
            reason: 'Postgrest error 42501 expected for RLS violation');
      }
    });

    test('3. Live Supabase Auth rejects invalid credentials with specific AuthException', () async {
      if (!hasCredentials) return;

      final client = SupabaseClient(
        supabaseUrl,
        supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      try {
        await client.auth.signInWithPassword(
          email: 'nonexistent.verifier.${DateTime.now().millisecondsSinceEpoch}@gmail.com',
          password: 'WrongPassword999!',
        );
        fail('Sign in with wrong credentials should fail');
      } on AuthException catch (e) {
        expect(e.statusCode, equals('400'));
        expect(e.code, equals('invalid_credentials'));
      }
    });

    test('4. Live Storage bucket memory-photos exists and restricts unauthenticated access', () async {
      if (!hasCredentials) return;

      final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

      // Unauthenticated access to private bucket
      final listRes = await client.storage.from('memory-photos').list();
      expect(listRes, isEmpty,
          reason: 'Private memory-photos bucket must return empty to unauthenticated users');
    });
  });
}
