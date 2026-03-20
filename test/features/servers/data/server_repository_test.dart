import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AppDatabase db;
  late _MockSecureStorage mockStorage;
  late ServerRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockStorage = _MockSecureStorage();
    repository = ServerRepository(db: db, storage: mockStorage);
  });

  tearDown(() async => db.close());

  group('ServerRepository', () {
    test('saveServer inserts record and returns it with a generated id', () async {
      when(
        () => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      final record = await repository.saveServer(
        name: 'ComicOPDS',
        url: 'https://comicopds.genjack.net/opds',
        username: 'stump',
        password: 'stump',
        opdsVersion: 'opds1',
      );

      expect(record.id, isPositive);
      expect(record.name, 'ComicOPDS');
      expect(record.url, 'https://comicopds.genjack.net/opds');
      expect(record.opdsVersion, 'opds1');
    });

    test('watchAllServers reflects saved server immediately', () async {
      when(
        () => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      expect(await repository.watchAllServers().first, isEmpty);

      await repository.saveServer(
        name: 'Server A',
        url: 'https://example.com/opds',
        username: null,
        password: null,
        opdsVersion: 'opds2',
      );

      final servers = await repository.watchAllServers().first;
      expect(servers, hasLength(1));
      expect(servers.first.name, 'Server A');
    });

    test('watchCount emits 0 with empty db', () async {
      expect(await repository.watchCount().first, 0);
    });

    test('saveServer writes password to secure storage keyed by server id', () async {
      when(
        () => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      final record = await repository.saveServer(
        name: 'Secure Server',
        url: 'https://example.com/opds',
        username: 'admin',
        password: 'secret',
        opdsVersion: 'opds1',
      );

      verify(
        () => mockStorage.write(key: 'server_password_${record.id}', value: 'secret'),
      ).called(1);
    });

    test('saveServer skips secure storage write when password is null', () async {
      await repository.saveServer(
        name: 'No Password',
        url: 'https://example.com/opds',
        username: null,
        password: null,
        opdsVersion: 'opds2',
      );

      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('updates and persists a server default reading mode', () async {
      final record = await repository.saveServer(
        name: 'Preset Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
        opdsVersion: 'opds2',
      );

      await repository.updateServerReadingPreset(
        serverId: record.id,
        defaultReadingMode: 'vertical',
      );

      final servers = await repository.watchAllServers().first;
      expect(servers.single.defaultReadingMode, 'vertical');
    });

    test('updates and persists server auto double-page preference', () async {
      final record = await repository.saveServer(
        name: 'Preset Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
        opdsVersion: 'opds2',
      );

      await repository.updateServerReadingPreset(
        serverId: record.id,
        autoDoublePage: true,
      );

      final servers = await repository.watchAllServers().first;
      expect(servers.single.autoDoublePage, isTrue);
    });

    test('updates and persists server URL and username', () async {
      final record = await repository.saveServer(
        name: 'Editable Server',
        url: 'https://example.com/opds',
        username: 'old-user',
        password: null,
        opdsVersion: 'opds2',
      );

      await repository.updateServerConnection(
        serverId: record.id,
        name: 'Edited Server',
        url: 'https://example.com/new-opds',
        username: 'new-user',
      );

      final servers = await repository.watchAllServers().first;
      expect(servers.single.name, 'Edited Server');
      expect(servers.single.url, 'https://example.com/new-opds');
      expect(servers.single.username, 'new-user');
    });

    test('updateServerConnection writes password when provided', () async {
      when(
        () => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      final record = await repository.saveServer(
        name: 'Secure Server',
        url: 'https://example.com/opds',
        username: 'admin',
        password: null,
        opdsVersion: 'opds1',
      );

      await repository.updateServerConnection(
        serverId: record.id,
        name: 'Secure Server',
        url: 'https://example.com/opds',
        username: 'admin',
        password: 'updated-secret',
      );

      verify(
        () => mockStorage.write(
          key: 'server_password_${record.id}',
          value: 'updated-secret',
        ),
      ).called(1);
    });
  });
}
