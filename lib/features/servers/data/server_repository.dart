import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/database.dart';
import '../../../core/storage/providers.dart';

final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  const storage = FlutterSecureStorage();
  return ServerRepository(db: db, storage: storage);
});

final savedServersProvider = StreamProvider<List<ServerRecord>>((ref) {
  return ref.watch(serverRepositoryProvider).watchAllServers();
});

final serverCountProvider = StreamProvider<int>((ref) {
  return ref.watch(serverRepositoryProvider).watchCount();
});

class ServerRepository {
  ServerRepository({required AppDatabase db, required FlutterSecureStorage storage})
      : _db = db,
        _storage = storage;

  final AppDatabase _db;
  final FlutterSecureStorage _storage;

  static String _passwordKey(int id) => 'server_password_$id';

  Stream<List<ServerRecord>> watchAllServers() {
    return (_db.select(_db.serversTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchCount() {
    return watchAllServers().map((list) => list.length);
  }

  Future<ServerRecord> saveServer({
    required String name,
    required String url,
    String? username,
    String? password,
    String? defaultReadingMode,
    bool? autoDoublePage,
    required String opdsVersion,
  }) async {
    final id = await _db.into(_db.serversTable).insert(
          ServersTableCompanion.insert(
            name: name,
            url: url,
            username: Value(username),
            defaultReadingMode: defaultReadingMode == null
                ? const Value.absent()
                : Value(defaultReadingMode),
            autoDoublePage: autoDoublePage == null
                ? const Value.absent()
                : Value(autoDoublePage),
            opdsVersion: opdsVersion,
          ),
        );

    final record = await (_db.select(_db.serversTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    if (password != null && password.isNotEmpty) {
      await _storage.write(key: _passwordKey(id), value: password);
    }

    return record;
  }

  Future<void> updateServerReadingPreset({
    required int serverId,
    String? defaultReadingMode,
    bool? autoDoublePage,
  }) async {
    if (defaultReadingMode == null && autoDoublePage == null) {
      return;
    }

    await (_db.update(_db.serversTable)..where((t) => t.id.equals(serverId)))
        .write(
      ServersTableCompanion(
        defaultReadingMode: defaultReadingMode == null
            ? const Value.absent()
            : Value(defaultReadingMode),
        autoDoublePage: autoDoublePage == null
            ? const Value.absent()
            : Value(autoDoublePage),
      ),
    );
  }

  Future<void> updateServerConnection({
    required int serverId,
    required String name,
    required String url,
    String? username,
    String? password,
    String? opdsVersion,
  }) async {
    await (_db.update(_db.serversTable)..where((t) => t.id.equals(serverId))).write(
      ServersTableCompanion(
        name: Value(name),
        url: Value(url),
        username: Value(username),
        opdsVersion: opdsVersion == null
            ? const Value.absent()
            : Value(opdsVersion),
      ),
    );

    if (password != null && password.isNotEmpty) {
      await _storage.write(key: _passwordKey(serverId), value: password);
    }
  }

  Future<String?> getPassword(int serverId) {
    return _storage.read(key: _passwordKey(serverId));
  }

  Future<void> deleteServer(int id) async {
    await (_db.delete(_db.serversTable)..where((t) => t.id.equals(id))).go();
    await _storage.delete(key: _passwordKey(id));
  }
}
