import 'package:drift/native.dart';
import 'package:echomap/app.dart';
import 'package:echomap/data/database/app_database.dart';
import 'package:echomap/features/memories/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EchoMapApp smoke test - verifies navigation & home screen',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const EchoMapApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Verify app title and dashboard
    expect(find.text('EchoMap'), findsWidgets);
    expect(find.text('Surprise Me'), findsOneWidget);
    expect(find.text('Memory Capsule'), findsOneWidget);

    // Verify navigation bar destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Quick Add Memory button is present
    expect(find.text('Record a New Memory'), findsOneWidget);

    // Tap on Navigation Bar Settings tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Settings screen loaded
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Privacy Information'), findsOneWidget);

    await testDb.close();
  });
}
