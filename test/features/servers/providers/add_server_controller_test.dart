import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:comicrow/features/servers/providers/add_server_controller.dart';
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

  Future<void> setActiveServerId(int? serverId) async {
    selectedServerIds.add(serverId);
  }

  setUp(() {
    mockRepository = _MockServerRepository();
    selectedServerIds = <int?>[];
  });

  group('AddServerController.testConnection', () {
    test('fails validation when required fields are missing', () async {
      final controller = AddServerController(
        opdsClient: _FakeOpdsClient(OpdsVersion.opds2),
        repository: mockRepository,
        setActiveServerId: setActiveServerId,
      );

      await controller.testConnection(
        name: '',
        url: '',
        username: null,
        password: null,
      );

      expect(controller.state.status, AddServerStatus.failure);
      expect(controller.state.errorMessage, contains('required'));
    });

    test('sets success status and detected version for valid input', () async {
      final controller = AddServerController(
        opdsClient: _FakeOpdsClient(OpdsVersion.opds1),
        repository: mockRepository,
        setActiveServerId: setActiveServerId,
      );

      await controller.testConnection(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: 'user',
        password: 'pass',
      );

      expect(controller.state.status, AddServerStatus.success);
      expect(controller.state.detectedVersion, OpdsVersion.opds1);
      expect(controller.state.errorMessage, isNull);
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

      final controller = AddServerController(
        opdsClient: _FakeOpdsClient(OpdsVersion.opds1),
        repository: mockRepository,
        setActiveServerId: setActiveServerId,
      );

      // Simulate a successful test connection first
      await controller.testConnection(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: 'user',
        password: 'pass',
      );

      await controller.saveServer(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: 'user',
        password: 'pass',
      );

      expect(controller.state.status, AddServerStatus.saved);
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

      final controller = AddServerController(
        opdsClient: _FakeOpdsClient(OpdsVersion.opds1),
        repository: mockRepository,
        setActiveServerId: setActiveServerId,
      );

      await controller.testConnection(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
      );

      await controller.saveServer(
        name: 'Local Server',
        url: 'https://example.com/opds',
        username: null,
        password: null,
      );

      expect(controller.state.status, AddServerStatus.failure);
      expect(controller.state.errorMessage, contains('save'));
      expect(selectedServerIds, isEmpty);
    });
  });
}
