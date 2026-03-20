import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database.dart';
import '../../../core/storage/providers.dart';

final readProgressRepositoryProvider = Provider<ReadProgressRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReadProgressRepository(db);
});

class ReadProgressRepository {
  ReadProgressRepository(this._db);

  final AppDatabase _db;

  Future<int?> getSavedPage({
    required int serverId,
    required String publicationUrl,
  }) async {
    final row = await (_db.select(_db.readProgressTable)
          ..where((t) => t.serverId.equals(serverId))
          ..where((t) => t.publicationUrl.equals(publicationUrl))
          ..limit(1))
        .getSingleOrNull();
    return row?.currentPage;
  }

  Future<void> saveProgress({
    required int serverId,
    required String publicationUrl,
    required int currentPage,
    required int totalPages,
  }) async {
    final existing = await (_db.select(_db.readProgressTable)
          ..where((t) => t.serverId.equals(serverId))
          ..where((t) => t.publicationUrl.equals(publicationUrl))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.readProgressTable).insert(
            ReadProgressTableCompanion.insert(
              serverId: serverId,
              publicationUrl: publicationUrl,
              currentPage: Value(currentPage),
              totalPages: Value(totalPages),
              lastReadAt: Value(DateTime.now()),
            ),
          );
      return;
    }

    await (_db.update(_db.readProgressTable)
          ..where((t) => t.id.equals(existing.id)))
        .write(
      ReadProgressTableCompanion(
        currentPage: Value(currentPage),
        totalPages: Value(totalPages),
        lastReadAt: Value(DateTime.now()),
      ),
    );
  }
}
