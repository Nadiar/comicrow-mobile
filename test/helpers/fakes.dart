import 'package:comicrow/core/network/http_transport.dart';
import 'package:comicrow/core/opds/models.dart';
import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/features/library/providers/library_catalog_provider.dart';
import 'package:comicrow/features/reader/data/comic_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An [HttpTransport] that always throws [UnimplementedError].
///
/// Use in tests where the transport is required by a constructor but never
/// actually called (e.g. when overriding higher-level methods on the client).
class NoopHttpTransport implements HttpTransport {
  @override
  Future<HttpTextResponse> get(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }
}

/// A [ComicDownloader] that returns fixed bytes for every request.
class FakeComicDownloader implements ComicDownloader {
  FakeComicDownloader(this._bytes);

  final List<int> _bytes;
  final List<Uri> prefetchedUris = <Uri>[];

  @override
  Future<List<int>> downloadBytes(
    Uri uri, {
    String? username,
    String? password,
  }) async =>
      _bytes;

  @override
  Future<List<int>> downloadBytesWithHeaders(
    Uri uri, {
    Map<String, String>? headers,
  }) async =>
      _bytes;

  @override
  Future<List<int>?> prefetchBytes(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    prefetchedUris.add(uri);
    return _bytes;
  }
}

/// A minimal [LibraryBrowseController] for widget/integration tests.
class FakeLibraryBrowseController extends LibraryBrowseController {
  FakeLibraryBrowseController({
    List<OpdsEntry> entries = const [],
    String serverName = 'Main Library',
  })  : _entries = entries,
        _serverName = serverName;

  final List<OpdsEntry> _entries;
  final String _serverName;

  @override
  AsyncValue<LibraryBrowseState> build() {
    return AsyncValue.data(
      LibraryBrowseState(
        feed: OpdsFeed(
          version: OpdsVersion.opds2,
          title: 'Catalog',
          entries: _entries,
        ),
        currentUri: Uri.parse('https://example.com/opds'),
        canGoBack: false,
        serverId: 1,
        serverName: _serverName,
      ),
    );
  }

  @override
  Future<void> goBack() async {}

  @override
  Future<void> clearSearch() async {}

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> openEntry(OpdsEntry entry) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> search(String query) async {}

  @override
  Uri resolvePublicationUri(OpdsEntry entry) =>
      Uri.parse('https://example.com/demo.cbz');
}
