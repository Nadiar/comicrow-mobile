import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('ServerRecord')
class ServersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get username => text().nullable()();
  TextColumn get defaultReadingMode =>
      text().withDefault(const Constant('single'))();
  BoolColumn get autoDoublePage =>
      boolean().withDefault(const Constant(false))();
  TextColumn get opdsVersion => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'servers';
}

@DataClassName('ReadProgressRecord')
class ReadProgressTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  TextColumn get publicationUrl => text()();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'read_progress';
}

@DataClassName('DownloadRecord')
class DownloadsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  TextColumn get publicationUrl => text()();
  TextColumn get title => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  String get tableName => 'downloads';
}

@DriftDatabase(tables: [ServersTable, ReadProgressTable, DownloadsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for unit tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(readProgressTable);
          }
          if (from < 3) {
            await migrator.createTable(downloadsTable);
          }
          if (from < 4) {
            await migrator.addColumn(
              serversTable,
              serversTable.defaultReadingMode,
            );
          }
          if (from < 5) {
            await migrator.addColumn(
              serversTable,
              serversTable.autoDoublePage,
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/comicrow.db');
    return NativeDatabase.createInBackground(file);
  });
}
