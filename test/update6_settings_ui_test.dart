import 'package:drift/native.dart';
import 'package:echomap/data/database/app_database.dart';
import 'package:echomap/features/auth/providers/auth_providers.dart';
import 'package:echomap/features/auth/screens/cloud_backup_auth_screen.dart';
import 'package:echomap/features/memories/providers/database_provider.dart';
import 'package:echomap/features/memories/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen displays Local Mode by default with Cloud Backup option',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'cloud_backup_enabled': false,
    });
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cloudBackupEnabledProvider.overrideWith((ref) => CloudBackupModeNotifier()),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Settings headers
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Privacy & Data'), findsOneWidget);
    expect(find.text('Cloud Backup & Storage'), findsOneWidget);

    // Verify default Local Mode is active
    expect(find.text('Local Mode (Default)'), findsOneWidget);
    expect(find.text('100% offline & private on device'), findsOneWidget);
    expect(find.text('Sign In / Set Up Cloud Backup'), findsOneWidget);

    // Verify switch is off by default
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);

    await db.close();
  });

  testWidgets('CloudBackupAuthScreen displays Sign In and Sign Up forms with EchoMap branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CloudBackupAuthScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Cloud Backup Auth UI
    expect(find.text('Cloud Backup Sign In'), findsOneWidget);
    expect(find.text('Welcome Back to EchoMap'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Return to Local Mode'), findsOneWidget);

    // Toggle to Sign Up
    final signUpButton = find.text('Sign Up');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    expect(find.text('Create Cloud Account'), findsWidgets);
    expect(find.text('Confirm Password'), findsOneWidget);
  });
}
