import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database.dart';
import '../../reader/providers/reader_provider.dart';
import '../../servers/data/server_repository.dart';
import '../models/reading_mode_preset.dart';

final serverReadingPresetProvider = Provider.family<ReadingModePreset, ServerRecord>(
  (ref, server) {
    return ReadingModePreset(
      serverId: server.id,
      defaultReadingMode: ReadingModePreset.readingModeFromRaw(
        server.defaultReadingMode,
      ),
      autoDoublePage: server.autoDoublePage,
    );
  },
);

final readingPresetControllerProvider = Provider<ReadingPresetController>((ref) {
  return ReadingPresetController(ref.watch(serverRepositoryProvider));
});

class ReadingPresetController {
  ReadingPresetController(this._repository);

  final ServerRepository _repository;

  Future<void> savePreset({
    required int serverId,
    ReaderMode? defaultReadingMode,
    bool? autoDoublePage,
  }) {
    return _repository.updateServerReadingPreset(
      serverId: serverId,
      defaultReadingMode: defaultReadingMode?.name,
      autoDoublePage: autoDoublePage,
    );
  }
}