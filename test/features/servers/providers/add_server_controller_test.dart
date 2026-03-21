import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:comicrow/features/servers/providers/add_server_controller.dart';
import 'package:comicrow/features/settings/providers/app_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

class _FakeOpdsClient extends OpdsClient {
  _FakeOpdsClient(this.version) : super(transport: NoopHttpTransport());

  final OpdsVersion version;

  @override
  Future<OpdsVersion> detectVersion(
    Uri baseUri, {
    String? username,
    String? password,
  }) async {
    return version;
  }
}

class _MockServerRepository extends Mock implements ServerRepository {}

void main() {
  late _MockServerRepository mockRepository;
  late List<int?> selectedServerIds;

  setUp(() {
    mockRepository = _MockServerRepository();
    selectedServerIds = <int?>[];
  });

  ProviderContainer buildContainer(OpdsVersion version) {
    return ProviderContainer(
      overrides: [
        opdsClientProvider.overrideWithValue(_FakeOpdsClient(version)),
        serverRepositoryProvider.overrideWithValue(mockRepository),
        appPreferencesProvider.overrideWith(() {
          final controller = _TrackingAppPreferencesController(selectedServerIds);
          return controller;
        }),
      ],
    );
  }

  group('AddServerController.testConnection', () {
    test('fails validation when required fields are missing', () async {
      final container = buildContainer(OpdsVersion.opds2);
      addTearDown(container.dispose);

      await container
          .read(addServerControllerProvider.notifier)
          .testConnection(
            name: '',
            url: '',
            username: null,
            password: null,
          );

      final state = container.read(addServerControllerProvider);
      expect(state.status, AddServerStatus.failure);
      expect(state.errorMessage, contains('required'));
    });

    test('sets success status and detected version for valid input', () async {
      final container = buildContainer(OpdsVersion.opds1);
      addTearDown(container.dispose);

      await container
          .read(addServerControllerProvider.notifier)
          .testConnection(
            name: 'Local Server',
            url: 'https://example.com/opds',
            username: 'user',
            password: 'pass',
          );

      final state = container.read(addServerControllerProvider);
      expect(state.status, AddServerStatus.success);
      expect(state.detectedVersion, OpdsVersion.opds1);
      expect(state.errorMessage, isNull);
    });
  });

  group('AddServerController.saveServer', () {
    final fakeRecord = ServerRecord(
      id: 1,
      name: 'Local Server',
      url: 'https://example.com/opds',
      username: 'user',
      defaultReadingMode: 'single',
      autoDoublePage: false,
      opdsVersion: 'opds1',
      createdAt: DateTime(2026),
    );

    test('sets saved status on successful save', () async {
      when(
        () => mockRepository.saveServer(
          name: any(named: 'name'),
          url: any(named: 'url'),
          username: any(named: 'username'),
          password: any(named: 'password'),
          opdsVersion: any(named: 'opdsVersion'),
        ),
      ).thenAnswer((_) async => fakeRecord);

      final container = buildContainer(OpdsVersion.opds1);
      addTearDown(container.dispose);

      final notifier = container.read(addServerControllerProvider.notifier);

      // Simulate a successful test connection first
      await notifier.testConnection(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: 'user',
        password: 'pass',
      );

      await notifier.saveServer(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: 'user',
        password: 'pass',
      );

      final state = container.read(addServerControllerProvider);
      expect(state.status, AddServerStatus.saved);
      expect(selectedServerIds, equals([1]));
    });

    test('sets failure status when repository throws', () async {
      when(
        () => mockRepository.saveServer(
          name: any(named: 'name'),
          url: any(named: 'url'),
          username: any(named: 'username'),
          password: any(named: 'password'),
          opdsVersion: any(named: 'opdsVersion'),
        ),
      ).thenThrow(Exception('DB error'));

      final container = buildContainer(OpdsVersion.opds1);
      addTearDown(container.dispose);

      final notifier = container.read(addServerControllerProvider.notifier);

      await notifier.testConnection(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
      );

      await notifier.saveServer(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
      );

      final state = container.read(addServerControllerProvider);
      expect(state.status, AddServerStatus.failure);
      expect(state.errorMessage, contains('save'));
      expect(selectedServerIds, isEmpty);
    });
  });
}

/// An [AppPreferencesController] override that records calls to [setActiveServerId].
class _TrackingAppPreferencesController extends AppPreferencesController {
  _TrackingAppPreferencesController(this._ids);

  final List<int?> _ids;

  @override
  AppPreferencesState build() {
    // Skip SharedPreferences loading in tests.
    return const AppPreferencesState();
  }

  @override
  Future<void> setActiveServerId(int? serverId) async {
    _ids.add(serverId);
  }
}
