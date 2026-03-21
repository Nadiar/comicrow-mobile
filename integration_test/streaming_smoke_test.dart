import 'package:comicrow/app.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/library/providers/library_catalog_provider.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app shell loads and navigates across primary routes', (tester) async {
    final server = ServerRecord(
      id: 1,
      name: 'Main Library',
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
          serverCountProvider.overrideWith((ref) => Stream.value(1)),
          savedServersProvider.overrideWith((ref) => Stream.value([server])),
          libraryBrowseControllerProvider.overrideWith(
            FakeLibraryBrowseController.new,
          ),
        ],
        child: const ComicRowApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Source: Main Library'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Downloads'), findsOneWidget);

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(find.text('No active downloads'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Add OPDS Server'), findsOneWidget);

    await tester.tap(find.text('Add OPDS Server'));
    await tester.pumpAndSettle();
    expect(find.text('Add Server'), findsOneWidget);
  });
}
