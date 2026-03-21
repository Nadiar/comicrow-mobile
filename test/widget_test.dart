import 'package:flutter_test/flutter_test.dart';

import 'package:comicrow/app.dart';
import 'package:comicrow/core/opds/models.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/library/providers/library_catalog_provider.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('App shell renders libraries drawer and settings affordance', (
    WidgetTester tester,
  ) async {
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
          serverCountProvider.overrideWith((_) => Stream.value(1)),
          savedServersProvider.overrideWith((_) => Stream.value([server])),
          libraryBrowseControllerProvider.overrideWith(
            () => FakeLibraryBrowseController(
              entries: const [
                OpdsEntry(
                  title: 'Demo',
                  href: '/demo',
                  kind: OpdsEntryKind.navigation,
                ),
              ],
            ),
          ),
        ],
        child: const ComicRowApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Source: Main Library'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Libraries'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Main Library'), findsOneWidget);
  });
}
