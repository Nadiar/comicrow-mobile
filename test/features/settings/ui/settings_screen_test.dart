import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/settings/ui/settings_screen.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders settings sections and server row', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final server = ServerRecord(
      id: 1,
      name: 'My Server',
      url: 'https://example.com/opds',
      username: 'user',
      defaultReadingMode: 'single',
      autoDoublePage: false,
      opdsVersion: 'opds2',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedServersProvider.overrideWith((ref) => Stream.value([server])),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Servers'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('My Server'), findsOneWidget);
    expect(find.text('Add OPDS Server'), findsOneWidget);
    expect(find.text('Default reading mode'), findsOneWidget);
    expect(find.text('Global auto double-page in landscape'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cache'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    expect(find.text('Cache'), findsOneWidget);
  });
}
