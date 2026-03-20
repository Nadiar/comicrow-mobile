import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:comicrow/core/divina/divina_client.dart';
import 'package:comicrow/core/divina/models.dart';
import 'package:comicrow/core/opds/pse_client.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/reader/data/comic_downloader.dart';
import 'package:comicrow/features/downloads/data/download_repository.dart';
import 'package:comicrow/features/reader/data/read_progress_repository.dart';
import 'package:comicrow/features/reader/providers/reader_provider.dart';
import 'package:comicrow/features/settings/providers/app_preferences_provider.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_data.dart';

class _MockServerRepository extends Mock implements ServerRepository {}

class _MockReadProgressRepository extends Mock
  implements ReadProgressRepository {}

class _MockDownloadRepository extends Mock implements DownloadRepository {}

class _MapComicDownloader implements ComicDownloader {
  _MapComicDownloader(this._bytesByUri);

  final Map<String, List<int>> _bytesByUri;
  final List<Uri> prefetchedUris = <Uri>[];

  @override
  Future<List<int>> downloadBytes(
    Uri uri, {
    String? username,
    String? password,
  }) async {
    final bytes = _bytesByUri[uri.toString()];
    if (bytes == null) {
      throw Exception('Missing test bytes for ${uri.toString()}');
    }
    return bytes;
  }

  @override
  Future<List<int>> downloadBytesWithHeaders(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final bytes = _bytesByUri[uri.toString()];
    if (bytes == null) {
      throw Exception('Missing test bytes for ${uri.toString()}');
    }
    return bytes;
  }

  @override
  Future<List<int>?> prefetchBytes(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    prefetchedUris.add(uri);
    return downloadBytesWithHeaders(uri, headers: headers);
  }
}

class _FakeDivinaClient extends DivinaClient {
  _FakeDivinaClient({required this.manifest}) : super();

  final DivinaManifest manifest;

  @override
  Future<DivinaManifest> fetchManifest(
    Uri manifestUri, {
    String? username,
    String? password,
  }) async {
    return manifest;
  }
}

class _FailingDivinaClient extends DivinaClient {
  _FailingDivinaClient() : super();

  @override
  Future<DivinaManifest> fetchManifest(
    Uri manifestUri, {
    String? username,
    String? password,
  }) async {
    throw const DivinaException('boom');
  }
}

class _FakePseClient extends PseClient {
  _FakePseClient({required this.document}) : super();

  final PseDocument document;

  @override
  Future<PseDocument> fetchPages(
    Uri pseUri, {
    String? username,
    String? password,
  }) async {
    return document;
  }
}

final _fakeImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

void main() {
  group('ReaderController', () {
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

    ProviderContainer buildContainer(List<int> zipBytes) {
      return ProviderContainer(overrides: [
        serverRepositoryProvider.overrideWithValue(mockRepo),
        comicDownloaderProvider
            .overrideWithValue(FakeComicDownloader(zipBytes)),
        readProgressRepositoryProvider.overrideWithValue(mockProgressRepo),
        downloadRepositoryProvider.overrideWithValue(mockDownloadRepo),
        preferredReadingDirectionProvider
            .overrideWithValue(ReadingDirectionPreference.ltr),
        serverReadingDirectionsProvider.overrideWithValue(
          const <int, ReadingDirectionPreference>{},
        ),
      ]);
    }

    test('loads pages from single-image archive', () async {
      final container = buildContainer(buildTestZip(['page001.png']));
      addTearDown(container.dispose);

      final sub = container.listen(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
      );
      expect(state.value?.pageCount, 1);
    });

    test('sorts pages alphabetically', () async {
      final container = buildContainer(
        buildTestZip(['page003.png', 'page001.png', 'page002.png']),
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
      );
      expect(state.value?.pageCount, 3);
    });

    test('errors when archive contains no images', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile(
          'metadata.xml',
          5,
          Uint8List.fromList([1, 2, 3, 4, 5]),
        ),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final container = buildContainer(zipBytes);
      addTearDown(container.dispose);

      final sub = container.listen(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
      );
      expect(state.hasError, isTrue);
    });

    test('setPage updates current page index', () async {
      final container = buildContainer(
        buildTestZip(['p1.jpg', 'p2.jpg', 'p3.jpg']),
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final key = readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz'));
      container.read(key.notifier).setPage(2);

      final state = container.read(key);
      expect(state.value?.currentPage, 2);
      verify(
        () => mockProgressRepo.saveProgress(
          serverId: 1,
          publicationUrl: 'https://example.com/book.cbz',
          currentPage: 2,
          totalPages: 3,
        ),
      ).called(1);
    });

    test('restores saved progress on load', () async {
      when(
        () => mockProgressRepo.getSavedPage(
          serverId: 1,
          publicationUrl: 'https://example.com/book.cbz',
        ),
      ).thenAnswer((_) async => 2);

      final container = buildContainer(
        buildTestZip(['p1.jpg', 'p2.jpg', 'p3.jpg']),
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(
        readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz')),
      );
      expect(state.value?.currentPage, 2);
    });

    test('setDisplayPage maps correctly in RTL mode', () async {
      final container = buildContainer(
        buildTestZip(['p1.jpg', 'p2.jpg', 'p3.jpg']),
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(const ReaderRequest(publicationUrl: 'https://example.com/book.cbz'));
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(key.notifier);
      notifier.toggleDirection();
      notifier.setDisplayPage(0);

      final state = container.read(key);
      expect(state.value?.direction, ReaderDirection.rtl);
      expect(state.value?.currentPage, 2);
    });

    test('setReadingMode updates current mode', () async {
      final container = buildContainer(
        buildTestZip(['p1.jpg', 'p2.jpg', 'p3.jpg']),
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(
        const ReaderRequest(publicationUrl: 'https://example.com/book.cbz'),
      );
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      container.read(key.notifier).setReadingMode(ReaderMode.vertical);

      final state = container.read(key);
      expect(state.value?.readingMode, ReaderMode.vertical);
    });

    test('initializes from the matching server default reading mode', () async {
      final preferredServer = ServerRecord(
        id: 2,
        name: 'Preferred',
        url: 'https://reader.example.com',
        username: 'reader',
        defaultReadingMode: 'double',
        autoDoublePage: true,
        opdsVersion: 'opds2',
        createdAt: DateTime(2026),
      );
      final fallbackServer = ServerRecord(
        id: 1,
        name: 'Fallback',
        url: 'https://example.com',
        username: 'user',
        defaultReadingMode: 'single',
        autoDoublePage: false,
        opdsVersion: 'opds1',
        createdAt: DateTime(2025),
      );

      when(() => mockRepo.watchAllServers())
          .thenAnswer((_) => Stream.value([fallbackServer, preferredServer]));
      when(() => mockRepo.getPassword(2)).thenAnswer((_) async => 'pass');

      final container = buildContainer(
        buildTestZip(['p1.jpg', 'p2.jpg', 'p3.jpg']),
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(
        const ReaderRequest(
          publicationUrl: 'https://reader.example.com/books/book.cbz',
        ),
      );
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(key);
      expect(state.value?.readingMode, ReaderMode.double);
      expect(state.value?.autoDoublePage, isTrue);
    });

    test('prefers DiViNa streaming when manifest link is provided', () async {
      final container = ProviderContainer(
        overrides: [
          serverRepositoryProvider.overrideWithValue(mockRepo),
          comicDownloaderProvider.overrideWithValue(
            _MapComicDownloader(
              {
                'https://example.com/pages/001.jpg': _fakeImageBytes,
                'https://example.com/pages/002.jpg': _fakeImageBytes,
              },
            ),
          ),
          readProgressRepositoryProvider.overrideWithValue(mockProgressRepo),
          downloadRepositoryProvider.overrideWithValue(mockDownloadRepo),
          preferredReadingDirectionProvider
              .overrideWithValue(ReadingDirectionPreference.ltr),
          serverReadingDirectionsProvider.overrideWithValue(
            const <int, ReadingDirectionPreference>{},
          ),
          divinaClientProvider.overrideWithValue(
            _FakeDivinaClient(
              manifest: const DivinaManifest(
                title: 'Stream',
                pages: [
                  DivinaPage(href: '/pages/001.jpg', index: 0),
                  DivinaPage(href: '/pages/002.jpg', index: 1),
                ],
              ),
            ),
          ),
          pseClientProvider.overrideWithValue(
            _FakePseClient(document: const PseDocument(pages: [])),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(
        const ReaderRequest(
          publicationUrl: 'https://example.com/book.cbz',
          divinaManifestUrl: 'https://example.com/manifest.json',
        ),
      );
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(key);
      expect(state.value?.pageCount, 2);
    });

    test('falls back to archive download when streaming fails', () async {
      final container = ProviderContainer(
        overrides: [
          serverRepositoryProvider.overrideWithValue(mockRepo),
          comicDownloaderProvider.overrideWithValue(
            _MapComicDownloader(
              {
                'https://example.com/book.cbz': buildTestZip(['p1.jpg', 'p2.jpg']),
              },
            ),
          ),
          readProgressRepositoryProvider.overrideWithValue(mockProgressRepo),
          downloadRepositoryProvider.overrideWithValue(mockDownloadRepo),
          preferredReadingDirectionProvider
              .overrideWithValue(ReadingDirectionPreference.ltr),
          serverReadingDirectionsProvider.overrideWithValue(
            const <int, ReadingDirectionPreference>{},
          ),
          divinaClientProvider.overrideWithValue(_FailingDivinaClient()),
          pseClientProvider.overrideWithValue(
            _FakePseClient(document: const PseDocument(pages: [])),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(
        const ReaderRequest(
          publicationUrl: 'https://example.com/book.cbz',
          divinaManifestUrl: 'https://example.com/manifest.json',
        ),
      );
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(key);
      expect(state.value?.pageCount, 2);
    });

    test('prefetches streaming window around current page', () async {
      final downloader = _MapComicDownloader(
        {
          'https://example.com/pages/001.jpg': _fakeImageBytes,
          'https://example.com/pages/002.jpg': _fakeImageBytes,
          'https://example.com/pages/003.jpg': _fakeImageBytes,
          'https://example.com/pages/004.jpg': _fakeImageBytes,
          'https://example.com/pages/005.jpg': _fakeImageBytes,
        },
      );
      final container = ProviderContainer(
        overrides: [
          serverRepositoryProvider.overrideWithValue(mockRepo),
          comicDownloaderProvider.overrideWithValue(downloader),
          readProgressRepositoryProvider.overrideWithValue(mockProgressRepo),
          downloadRepositoryProvider.overrideWithValue(mockDownloadRepo),
          preferredReadingDirectionProvider
              .overrideWithValue(ReadingDirectionPreference.ltr),
          serverReadingDirectionsProvider.overrideWithValue(
            const <int, ReadingDirectionPreference>{},
          ),
          divinaClientProvider.overrideWithValue(
            _FakeDivinaClient(
              manifest: const DivinaManifest(
                title: 'Stream',
                pages: [
                  DivinaPage(href: '/pages/001.jpg', index: 0),
                  DivinaPage(href: '/pages/002.jpg', index: 1),
                  DivinaPage(href: '/pages/003.jpg', index: 2),
                  DivinaPage(href: '/pages/004.jpg', index: 3),
                  DivinaPage(href: '/pages/005.jpg', index: 4),
                ],
              ),
            ),
          ),
          pseClientProvider.overrideWithValue(
            _FakePseClient(document: const PseDocument(pages: [])),
          ),
        ],
      );
      addTearDown(container.dispose);

      final key = readerControllerProvider(
        const ReaderRequest(
          publicationUrl: 'https://example.com/book.cbz',
          divinaManifestUrl: 'https://example.com/manifest.json',
        ),
      );
      final sub = container.listen(key, (_, _) {});
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 120));

      expect(downloader.prefetchedUris.length, greaterThanOrEqualTo(3));

      container.read(key.notifier).setPage(4);
      await Future.delayed(const Duration(milliseconds: 120));

      expect(
        downloader.prefetchedUris.map((u) => u.toString()),
        contains('https://example.com/pages/005.jpg'),
      );
    });
  });
}
