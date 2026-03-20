import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/downloads/data/download_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DownloadRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DownloadRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertQueued creates then updates existing record', () async {
    final first = await repository.upsertQueued(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
      title: 'Book A',
    );

    expect(first.title, 'Book A');
    expect(first.status, 'queued');

    final second = await repository.upsertQueued(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
      title: 'Book A Updated',
    );

    expect(second.id, first.id);
    expect(second.title, 'Book A Updated');
  });

  test('markComplete persists file info and status', () async {
    final queued = await repository.upsertQueued(
      serverId: 2,
      publicationUrl: 'https://example.com/other.cbz',
      title: 'Book B',
    );

    await repository.markComplete(
      id: queued.id,
      filePath: '/tmp/book.cbz',
      fileSize: 12345,
    );

    final found = await repository.findByServerAndUrl(
      serverId: 2,
      publicationUrl: 'https://example.com/other.cbz',
    );

    expect(found, isNotNull);
    expect(found!.status, 'complete');
    expect(found.filePath, '/tmp/book.cbz');
    expect(found.fileSize, 12345);
    expect(found.progress, 1);
  });
}
