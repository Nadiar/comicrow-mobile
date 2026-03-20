import 'package:comicrow/core/storage/database.dart';
import 'package:comicrow/features/reader/data/read_progress_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ReadProgressRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReadProgressRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('saveProgress inserts and updates records', () async {
    await repository.saveProgress(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
      currentPage: 3,
      totalPages: 10,
    );

    final first = await repository.getSavedPage(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
    );
    expect(first, 3);

    await repository.saveProgress(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
      currentPage: 6,
      totalPages: 10,
    );

    final second = await repository.getSavedPage(
      serverId: 1,
      publicationUrl: 'https://example.com/book.cbz',
    );
    expect(second, 6);
  });

  test('getSavedPage returns null when no progress exists', () async {
    final result = await repository.getSavedPage(
      serverId: 99,
      publicationUrl: 'https://example.com/none.cbz',
    );
    expect(result, isNull);
  });
}
