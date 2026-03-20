import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/downloads/data/download_repository.dart';
import 'package:comicrow/features/reader/data/comic_downloader.dart';
import 'package:comicrow/features/reader/data/read_progress_repository.dart';
import 'package:comicrow/features/reader/ui/reader_screen.dart';
import 'package:comicrow/features/reader/widgets/double_page_viewer.dart';
import 'package:comicrow/features/reader/widgets/single_page_viewer.dart';
import 'package:comicrow/features/reader/widgets/vertical_scroll_viewer.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:comicrow/features/settings/providers/app_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_data.dart';

class _MockServerRepository extends Mock implements ServerRepository {}

class _MockReadProgressRepository extends Mock
    implements ReadProgressRepository {}

class _MockDownloadRepository extends Mock implements DownloadRepository {}

void main() {
  group('ReaderScreen', () {
    late _MockServerRepository mockRepo;
    late _MockReadProgressRepository mockProgressRepo;
    late _MockDownloadRepository mockDownloadRepo;

    setUp(() {
      mockRepo = _MockServerRepository();
      mockProgressRepo = _MockReadProgressRepository();
      mockDownloadRepo = _MockDownloadRepository();

      final server = ServerRecord(
        id: 1,
        name: 'Test',
        url: 'https://example.com',
        username: 'user',
        defaultReadingMode: 'single',
        autoDoublePage: false,
        opdsVersion: 'opds1',
        createdAt: DateTime(2025),
      );

      when(() => mockRepo.watchAllServers())
          .thenAnswer((_) => Stream.value([server]));
      when(() => mockRepo.getPassword(1)).thenAnswer((_) async => 'pass');
      when(
        () => mockProgressRepo.getSavedPage(
          serverId: any(named: 'serverId'),
          publicationUrl: any(named: 'publicationUrl'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockProgressRepo.saveProgress(
          serverId: any(named: 'serverId'),
          publicationUrl: any(named: 'publicationUrl'),
          currentPage: any(named: 'currentPage'),
          totalPages: any(named: 'totalPages'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockDownloadRepo.findByServerAndUrl(
          serverId: any(named: 'serverId'),
          publicationUrl: any(named: 'publicationUrl'),
        ),
      ).thenAnswer((_) async => null);
    });

    Widget buildApp({
      required Size size,
      bool autoDoublePage = false,
    }) {
      return ProviderScope(
        overrides: [
          serverRepositoryProvider.overrideWithValue(mockRepo),
          comicDownloaderProvider.overrideWithValue(
            FakeComicDownloader(buildTestZip(['p1.png', 'p2.png', 'p3.png'])),
          ),
          readProgressRepositoryProvider.overrideWithValue(mockProgressRepo),
          downloadRepositoryProvider.overrideWithValue(mockDownloadRepo),
          preferredReadingDirectionProvider
              .overrideWithValue(ReadingDirectionPreference.ltr),
          autoDoublePageProvider.overrideWithValue(autoDoublePage),
        ],
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: const MaterialApp(
            home: ReaderScreen(
              publicationUrl: 'https://example.com/book.cbz',
              title: 'Reader Test',
            ),
          ),
        ),
      );
    }

    Future<void> pumpReader(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders single-page viewer by default in portrait', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(size: const Size(400, 800)));
      await pumpReader(tester);

      expect(find.byType(SinglePageViewer), findsOneWidget);
      expect(find.byType(DoublePageViewer), findsNothing);
      expect(find.byType(VerticalScrollViewer), findsNothing);
      expect(find.text('Single page'), findsOneWidget);
    });

    testWidgets('auto-switches to double-page viewer in landscape', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(size: const Size(900, 500), autoDoublePage: true),
      );
      await pumpReader(tester);
      await tester.pump();

      expect(find.byType(DoublePageViewer), findsOneWidget);
    });

    testWidgets('mode menu switches to vertical scroll viewer', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(size: const Size(400, 800)));
      await pumpReader(tester);

      await tester.tap(find.byTooltip('Reading mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Vertical scroll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerticalScrollViewer), findsOneWidget);
    });

    testWidgets('manual mode override takes precedence over auto landscape', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(size: const Size(900, 500), autoDoublePage: true),
      );
      await pumpReader(tester);

      expect(find.byType(DoublePageViewer), findsOneWidget);

      await tester.tap(find.byTooltip('Reading mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Vertical scroll'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VerticalScrollViewer), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(VerticalScrollViewer), findsOneWidget);
      expect(find.byType(DoublePageViewer), findsNothing);
    });
  });
}