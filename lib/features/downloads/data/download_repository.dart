import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database.dart';
import '../../../core/storage/providers.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DownloadRepository(db);
});

final activeDownloadsProvider = StreamProvider<List<DownloadRecord>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchByStatuses(
        const ['queued', 'downloading'],
      );
});

final completedDownloadsProvider = StreamProvider<List<DownloadRecord>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchByStatuses(
        const ['complete'],
      );
});

class DownloadRepository {
  DownloadRepository(this._db);

  final AppDatabase _db;

  Stream<List<DownloadRecord>> watchByStatuses(List<String> statuses) {
    return (_db.select(_db.downloadsTable)
          ..where((t) => t.status.isIn(statuses))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<DownloadRecord?> findByServerAndUrl({
    required int serverId,
    required String publicationUrl,
  }) {
    return (_db.select(_db.downloadsTable)
          ..where((t) => t.serverId.equals(serverId))
          ..where((t) => t.publicationUrl.equals(publicationUrl))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<DownloadRecord> upsertQueued({
    required int serverId,
    required String publicationUrl,
    required String title,
    String? thumbnailUrl,
  }) async {
    final existing = await findByServerAndUrl(
      serverId: serverId,
      publicationUrl: publicationUrl,
    );

    if (existing != null) {
      await (_db.update(_db.downloadsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        DownloadsTableCompanion(
          title: Value(title),
          thumbnailUrl: Value(thumbnailUrl),
          status: const Value('queued'),
          progress: const Value(0),
          filePath: const Value(null),
          downloadedAt: const Value(null),
          fileSize: const Value(0),
        ),
      );

      return (_db.select(_db.downloadsTable)..where((t) => t.id.equals(existing.id)))
          .getSingle();
    }

    final id = await _db.into(_db.downloadsTable).insert(
          DownloadsTableCompanion.insert(
            serverId: serverId,
            publicationUrl: publicationUrl,
            title: title,
            thumbnailUrl: Value(thumbnailUrl),
          ),
        );
    return (_db.select(_db.downloadsTable)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> markDownloading(int id) {
    return (_db.update(_db.downloadsTable)..where((t) => t.id.equals(id))).write(
      const DownloadsTableCompanion(
        status: Value('downloading'),
        progress: Value(0),
      ),
    );
  }

  Future<void> markComplete({
    required int id,
    required String filePath,
    required int fileSize,
  }) {
    return (_db.update(_db.downloadsTable)..where((t) => t.id.equals(id))).write(
      DownloadsTableCompanion(
        status: const Value('complete'),
        progress: const Value(1),
        filePath: Value(filePath),
        fileSize: Value(fileSize),
        downloadedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (_db.update(_db.downloadsTable)..where((t) => t.id.equals(id))).write(
      const DownloadsTableCompanion(
        status: Value('failed'),
      ),
    );
  }

  Future<void> deleteById(int id) {
    return (_db.delete(_db.downloadsTable)..where((t) => t.id.equals(id))).go();
  }
}
