import 'dart:convert';

import 'package:comicrow/core/opds/models.dart';
import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/library/providers/library_catalog_provider.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:comicrow/features/servers/providers/add_server_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fakes.dart';

class _FakeOpdsClient extends OpdsClient {
  _FakeOpdsClient(this.feedsByUri) : super(transport: NoopHttpTransport());

  final Map<String, OpdsFeed> feedsByUri;

  @override
  Future<OpdsFeed> fetchFeed(
    Uri feedUri, {
    String? username,
    String? password,
  }) async {
    final feed = feedsByUri[feedUri.toString()];
    if (feed == null) {
      throw Exception('Missing fake feed for ${feedUri.toString()}');
    }
    return feed;
  }
}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late _MockSecureStorage mockStorage;
  late ServerRepository repository;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockStorage = _MockSecureStorage();
    repository = ServerRepository(db: db, storage: mockStorage);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'stump');
  });

  tearDown(() async {
    await db.close();
  });

  test('loads feed from first saved server', () async {
    await repository.saveServer(
      name: 'Test Server',
      url: 'https://comicopds.genjack.net',
      username: 'stump',
      password: 'stump',
      opdsVersion: 'opds2',
    );

    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) => repository.watchAllServers()),
        serverRepositoryProvider.overrideWithValue(repository),
        opdsClientProvider.overrideWithValue(
          _FakeOpdsClient(
            {
              'https://comicopds.genjack.net': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Root',
                entries: [
                  OpdsEntry(
                    title: 'One',
                    href: '/one',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(libraryBrowseControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    final state = container.read(libraryBrowseControllerProvider);
    expect(state.hasValue, true);
    expect(state.value!.feed.title, 'Root');
    expect(state.value!.feed.entries, hasLength(1));
    expect(state.value!.thumbnailHeaders, isNotNull);
    final expectedAuth = 'Basic ${base64Encode(utf8.encode('stump:stump'))}';
    expect(
      state.value!.thumbnailHeaders!['Authorization'],
      expectedAuth,
    );
  });

  test('throws when no servers are configured', () async {
    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) => repository.watchAllServers()),
        serverRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(libraryBrowseControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    final state = container.read(libraryBrowseControllerProvider);
    expect(state.hasError, true);
    expect(state.error, isA<LibraryCatalogException>());
  });

  test('openEntry navigates to sub-feed and loadNextPage appends results', () async {
    await repository.saveServer(
      name: 'Test Server',
      url: 'https://comicopds.genjack.net',
      username: 'stump',
      password: 'stump',
      opdsVersion: 'opds2',
    );

    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) => repository.watchAllServers()),
        serverRepositoryProvider.overrideWithValue(repository),
        opdsClientProvider.overrideWithValue(
          _FakeOpdsClient(
            {
              'https://comicopds.genjack.net': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Root',
                entries: [
                  OpdsEntry(
                    title: 'Browse Authors',
                    href: '/authors',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
              'https://comicopds.genjack.net/authors': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Authors',
                nextHref: '/authors?page=2',
                entries: [
                  OpdsEntry(
                    title: 'Author A',
                    href: '/authors/a',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
              'https://comicopds.genjack.net/authors?page=2': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Authors',
                entries: [
                  OpdsEntry(
                    title: 'Author B',
                    href: '/authors/b',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(libraryBrowseControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final notifier = container.read(libraryBrowseControllerProvider.notifier);
    final rootState = container.read(libraryBrowseControllerProvider).value!;
    await notifier.openEntry(rootState.feed.entries.first);

    final afterOpen = container.read(libraryBrowseControllerProvider).value!;
    expect(afterOpen.feed.title, 'Authors');
    expect(afterOpen.canGoBack, true);

    await notifier.loadNextPage();
    final afterNext = container.read(libraryBrowseControllerProvider).value!;
    expect(afterNext.feed.entries, hasLength(2));
    expect(afterNext.feed.entries.last.title, 'Author B');
  });

  test('search loads search feed and clearSearch restores root feed', () async {
    await repository.saveServer(
      name: 'Test Server',
      url: 'https://comicopds.genjack.net',
      username: 'stump',
      password: 'stump',
      opdsVersion: 'opds2',
    );

    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) => repository.watchAllServers()),
        serverRepositoryProvider.overrideWithValue(repository),
        opdsClientProvider.overrideWithValue(
          _FakeOpdsClient(
            {
              'https://comicopds.genjack.net': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Root',
                searchUrl: '/search{?searchTerms}',
                entries: [
                  OpdsEntry(
                    title: 'Browse Authors',
                    href: '/authors',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
              'https://comicopds.genjack.net/search?q=batman': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Search Results',
                searchUrl: '/search{?searchTerms}',
                entries: [
                  OpdsEntry(
                    title: 'Batman 1',
                    href: '/pubs/batman-1.cbz',
                    kind: OpdsEntryKind.publication,
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(libraryBrowseControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    final notifier = container.read(libraryBrowseControllerProvider.notifier);
    await notifier.search('batman');

    final searched = container.read(libraryBrowseControllerProvider).value!;
    expect(searched.feed.title, 'Search Results');
    expect(searched.feed.entries.first.title, 'Batman 1');
    expect(
      searched.currentUri.toString(),
      'https://comicopds.genjack.net/search?q=batman',
    );

    await notifier.clearSearch();
    final restored = container.read(libraryBrowseControllerProvider).value!;
    expect(restored.feed.title, 'Root');
    expect(restored.currentUri.toString(), 'https://comicopds.genjack.net');
  });

  test('refresh reloads the current feed URI', () async {
    await repository.saveServer(
      name: 'Test Server',
      url: 'https://comicopds.genjack.net',
      username: 'stump',
      password: 'stump',
      opdsVersion: 'opds2',
    );

    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) => repository.watchAllServers()),
        serverRepositoryProvider.overrideWithValue(repository),
        opdsClientProvider.overrideWithValue(
          _FakeOpdsClient(
            {
              'https://comicopds.genjack.net': const OpdsFeed(
                version: OpdsVersion.opds2,
                title: 'Root Updated',
                entries: [
                  OpdsEntry(
                    title: 'Entry',
                    href: '/entry',
                    kind: OpdsEntryKind.navigation,
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(libraryBrowseControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    final notifier = container.read(libraryBrowseControllerProvider.notifier);
    await notifier.refresh();

    final refreshed = container.read(libraryBrowseControllerProvider).value!;
    expect(refreshed.feed.title, 'Root Updated');
  });
}
