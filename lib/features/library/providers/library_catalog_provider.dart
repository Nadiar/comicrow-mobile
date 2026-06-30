import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';

import '../../../core/network/auth.dart';

import '../../../core/opds/models.dart';
import '../../../core/opds/opds_client.dart';
import '../../../core/storage/database.dart';
import '../../servers/data/server_repository.dart';
import '../../servers/providers/add_server_controller.dart';
import '../../settings/providers/app_preferences_provider.dart';

final libraryBrowseControllerProvider =
    NotifierProvider.autoDispose<LibraryBrowseController, AsyncValue<LibraryBrowseState>>(
      LibraryBrowseController.new,
    );

class LibraryBrowseState {
  const LibraryBrowseState({
    required this.feed,
    required this.currentUri,
    required this.canGoBack,
    required this.serverId,
    required this.serverName,
    this.thumbnailHeaders,
    this.isLoadingNextPage = false,
  });

  final OpdsFeed feed;
  final Uri currentUri;
  final bool canGoBack;
  final int serverId;
  final String serverName;
  final Map<String, String>? thumbnailHeaders;
  final bool isLoadingNextPage;

  LibraryBrowseState copyWith({
    OpdsFeed? feed,
    Uri? currentUri,
    bool? canGoBack,
    int? serverId,
    String? serverName,
    Map<String, String>? thumbnailHeaders,
    bool clearThumbnailHeaders = false,
    bool? isLoadingNextPage,
  }) {
    return LibraryBrowseState(
      feed: feed ?? this.feed,
      currentUri: currentUri ?? this.currentUri,
      canGoBack: canGoBack ?? this.canGoBack,
        serverId: serverId ?? this.serverId,
        serverName: serverName ?? this.serverName,
      thumbnailHeaders: clearThumbnailHeaders
          ? null
          : (thumbnailHeaders ?? this.thumbnailHeaders),
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
    );
  }
}

class LibraryBrowseController extends Notifier<AsyncValue<LibraryBrowseState>> {
  late final ServerRepository _repository;
  late final OpdsClient _client;
  late final int? _activeServerId;
  final List<Uri> _history = <Uri>[];
  Uri? _rootUri;

  ServerRecord? _server;
  String? _password;

  @override
  AsyncValue<LibraryBrowseState> build() {
    _repository = ref.watch(serverRepositoryProvider);
    _client = ref.watch(opdsClientProvider);
    _activeServerId = ref.watch(activeLibraryServerIdProvider);
    Future.microtask(_initialize);
    return const AsyncValue.loading();
  }

  Future<void> _initialize() async {
    try {
      final servers = await _repository.watchAllServers().first;
      if (servers.isEmpty) {
        throw const LibraryCatalogException('No OPDS server configured yet.');
      }

        _server = servers.where((server) => server.id == _activeServerId).firstOrNull ??
          servers.first;
      _password = await _repository.getPassword(_server!.id);
      final thumbnailHeaders = _buildThumbnailHeaders(
        username: _server?.username,
        password: _password,
      );
      final rootUri = Uri.parse(_server!.url);
      _rootUri = rootUri;
      final feed = await _fetchFeed(rootUri);
      if (!ref.mounted) return;
      state = AsyncValue.data(
        LibraryBrowseState(
          feed: feed,
          currentUri: rootUri,
          canGoBack: false,
          serverId: _server!.id,
          serverName: _server!.name,
          thumbnailHeaders: thumbnailHeaders,
        ),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> openEntry(OpdsEntry entry) async {
    if (entry.kind != OpdsEntryKind.navigation) {
      return;
    }

    final currentState = state.value;
    if (currentState == null || _server == null) {
      return;
    }

    final nextUri = currentState.currentUri.resolve(entry.href);
    _history.add(currentState.currentUri);
    state = const AsyncValue.loading();

    try {
      final feed = await _fetchFeed(nextUri);
      state = AsyncValue.data(
        currentState.copyWith(
          feed: feed,
          currentUri: nextUri,
          canGoBack: _history.isNotEmpty,
          isLoadingNextPage: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> goBack() async {
    if (_history.isEmpty || state.isLoading || _server == null) {
      return;
    }

    final currentState = state.value;
    if (currentState == null) {
      return;
    }

    final previousUri = _history.removeLast();
    state = const AsyncValue.loading();
    try {
      final feed = await _fetchFeed(previousUri);
      state = AsyncValue.data(
        LibraryBrowseState(
          feed: feed,
          currentUri: previousUri,
          canGoBack: _history.isNotEmpty,
          serverId: currentState.serverId,
          serverName: currentState.serverName,
          thumbnailHeaders: currentState.thumbnailHeaders,
          isLoadingNextPage: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.feed.nextHref == null) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingNextPage: true));
    final nextUri = currentState.currentUri.resolve(currentState.feed.nextHref!);

    try {
      final nextFeed = await _fetchFeed(nextUri);
      final mergedFeed = currentState.feed.copyWith(
        entries: <OpdsEntry>[...currentState.feed.entries, ...nextFeed.entries],
        nextHref: nextFeed.nextHref,
        clearNextHref: nextFeed.nextHref == null,
      );

      state = AsyncValue.data(
        currentState.copyWith(feed: mergedFeed, isLoadingNextPage: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final currentState = state.value;
    if (currentState == null || _server == null) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingNextPage: true));
    try {
      final feed = await _fetchFeed(currentState.currentUri);
      state = AsyncValue.data(
        currentState.copyWith(
          feed: feed,
          isLoadingNextPage: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      await clearSearch();
      return;
    }

    final currentState = state.value;
    if (currentState == null || _server == null) {
      return;
    }

    final searchUrl = currentState.feed.searchUrl;
    if (searchUrl == null || searchUrl.isEmpty) {
      throw const LibraryCatalogException('Search is not available for this catalog.');
    }

    state = const AsyncValue.loading();
    try {
      var template = searchUrl;
      final rawUri = currentState.currentUri.resolve(searchUrl);
      
      if (!searchUrl.contains('{searchTerms}') && !searchUrl.contains('{searchTerm}')) {
        final fetchedTemplate = await _getSearchTemplate(rawUri);
        if (fetchedTemplate != null) {
          template = fetchedTemplate;
        }
      }

      final searchUri = _resolveSearchUri(
        currentState.currentUri,
        template,
        trimmedQuery,
      );

      final searchFeed = await _client.fetchFeed(
        searchUri,
        username: _server?.username,
        password: _password,
      );
      state = AsyncValue.data(
        currentState.copyWith(
          feed: searchFeed,
          currentUri: searchUri,
          isLoadingNextPage: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String?> _getSearchTemplate(Uri searchUri) async {
    try {
      final response = await _client.fetchRaw(
        searchUri,
        username: _server?.username,
        password: _password,
      );
      
      final document = XmlDocument.parse(response.body);
      final searchDesc = document.findElements('OpenSearchDescription').firstOrNull ??
          document.findAllElements('OpenSearchDescription').firstOrNull;
      if (searchDesc != null) {
        final urls = searchDesc.findElements('Url');
        for (final url in urls) {
          final type = url.getAttribute('type') ?? '';
          if (type.contains('application/atom+xml') ||
              type.contains('application/opds+json') ||
              type.contains('application/xml') ||
              type.contains('text/xml')) {
            final template = url.getAttribute('template');
            if (template != null && template.isNotEmpty) {
              return template;
            }
          }
        }
        final anyUrl = urls.firstOrNull;
        if (anyUrl != null) {
          final template = anyUrl.getAttribute('template');
          if (template != null && template.isNotEmpty) {
            return template;
          }
        }
      }
    } catch (e) {
      // Log template parsing error silently or fallback
    }
    return null;
  }

  Future<void> clearSearch() async {
    final rootUri = _rootUri;
    final currentState = state.value;
    if (rootUri == null || currentState == null) {
      return;
    }

    state = const AsyncValue.loading();
    try {
      final feed = await _fetchFeed(rootUri);
      _history.clear();
      state = AsyncValue.data(
        currentState.copyWith(
          feed: feed,
          currentUri: rootUri,
          canGoBack: false,
          isLoadingNextPage: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Uri _resolveSearchUri(Uri baseUri, String searchHref, String query) {
    final encodedQuery = Uri.encodeQueryComponent(query);
    
    var href = searchHref
        .replaceAll('{searchTerms}', encodedQuery)
        .replaceAll('{searchTerm}', encodedQuery)
        .replaceAll('{?searchTerms}', '?q=$encodedQuery')
        .replaceAll('{?searchTerm}', '?q=$encodedQuery');

    href = href.replaceAll(RegExp(r'\{[^\}]+\}'), '');

    final resolved = baseUri.resolve(href);
    if (!searchHref.contains('{searchTerms}') && 
        !searchHref.contains('{searchTerm}') && 
        !resolved.queryParameters.containsKey('q') &&
        !resolved.queryParameters.containsKey('query')) {
      final parameters = Map<String, String>.from(resolved.queryParameters);
      parameters['q'] = query;
      return resolved.replace(queryParameters: parameters);
    }

    return resolved;
  }

  Uri resolvePublicationUri(OpdsEntry entry) {
    final currentState = state.value;
    if (entry.kind != OpdsEntryKind.publication || currentState == null) {
      throw const LibraryCatalogException('Cannot open publication from current state.');
    }
    return currentState.currentUri.resolve(entry.href);
  }

  Future<OpdsFeed> _fetchFeed(Uri feedUri) {
    return _client.fetchFeed(
      feedUri,
      username: _server?.username,
      password: _password,
    );
  }

  Map<String, String>? _buildThumbnailHeaders({
    String? username,
    String? password,
  }) {
    final headers = buildBasicAuthHeaders(username: username, password: password);
    return headers.isEmpty ? null : headers;
  }
}

class LibraryCatalogException implements Exception {
  const LibraryCatalogException(this.message);

  final String message;

  @override
  String toString() => 'LibraryCatalogException: $message';
}