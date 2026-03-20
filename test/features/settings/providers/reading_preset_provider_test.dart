import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/reader/providers/reader_provider.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:comicrow/features/settings/providers/reading_preset_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockServerRepository extends Mock implements ServerRepository {}

void main() {
  group('ReadingPreset providers', () {
    test('serverReadingPresetProvider maps ServerRecord fields', () {
      final server = ServerRecord(
        id: 1,
        name: 'Server',
        url: 'https://example.com/opds',
        username: 'user',
        defaultReadingMode: 'vertical',
        autoDoublePage: true,
        opdsVersion: 'opds2',
        createdAt: DateTime(2026),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final preset = container.read(serverReadingPresetProvider(server));
      expect(preset.serverId, 1);
      expect(preset.defaultReadingMode, ReaderMode.vertical);
      expect(preset.autoDoublePage, isTrue);
    });

    test('readingPresetControllerProvider saves converted mode and flag', () async {
      final repository = _MockServerRepository();
      when(
        () => repository.updateServerReadingPreset(
          serverId: any(named: 'serverId'),
          defaultReadingMode: any(named: 'defaultReadingMode'),
          autoDoublePage: any(named: 'autoDoublePage'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          serverRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(readingPresetControllerProvider).savePreset(
            serverId: 3,
            defaultReadingMode: ReaderMode.double,
            autoDoublePage: true,
          );

      verify(
        () => repository.updateServerReadingPreset(
          serverId: 3,
          defaultReadingMode: 'double',
          autoDoublePage: true,
        ),
      ).called(1);
    });
  });
}