import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth.dart';
import '../../../core/storage/database.dart';
import '../../../core/divina/divina_client.dart';
import '../../../core/opds/pse_client.dart';
import '../../downloads/data/download_repository.dart';
import '../../servers/data/server_repository.dart';
import '../../settings/models/reading_mode_preset.dart';
import '../../settings/providers/app_preferences_provider.dart';
import '../data/comic_downloader.dart';
import '../data/read_progress_repository.dart';
import '../services/page_cache_manager.dart';

final pseClientProvider = Provider<PseClient>((ref) => PseClient());
final divinaClientProvider = Provider<DivinaClient>((ref) => DivinaClient());

class ReaderRequest {
  const ReaderRequest({
    required this.publicationUrl,
    this.pseStreamUrl,
    this.divinaManifestUrl,
    this.thumbnailUrl,
  });

  final String publicationUrl;
  final String? pseStreamUrl;
  final String? divinaManifestUrl;
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) {
    return other is ReaderRequest &&
        other.publicationUrl == publicationUrl &&
        other.pseStreamUrl == pseStreamUrl &&
        other.divinaManifestUrl == divinaManifestUrl &&
        other.thumbnailUrl == thumbnailUrl;
  }

  @override
  int get hashCode => Object.hash(
    publicationUrl,
    pseStreamUrl,
    divinaManifestUrl,
    thumbnailUrl,
  );
}

final readerControllerProvider = StateNotifierProvider.autoDispose
    .family<ReaderController, AsyncValue<ReaderState>, ReaderRequest>(
  (ref, request) {
    return ReaderController(
      request: request,
      repository: ref.watch(serverRepositoryProvider),
      downloader: ref.watch(comicDownloaderProvider),
      progressRepository: ref.watch(readProgressRepositoryProvider),
      downloadRepository: ref.watch(downloadRepositoryProvider),
      pageCacheManager: ref.watch(pageCacheManagerProvider),
      pseClient: ref.watch(pseClientProvider),
      divinaClient: ref.watch(divinaClientProvider),
      defaultDirection: ref.watch(preferredReadingDirectionProvider) ==
              ReadingDirectionPreference.rtl
          ? ReaderDirection.rtl
          : ReaderDirection.ltr,
      serverReadingDirections: ref.watch(serverReadingDirectionsProvider),
    );
  },
);

enum ReaderDirection { ltr, rtl }
enum ReaderMode { single, double, vertical }

class ReaderState {
  const ReaderState({
    required this.pages,
    this.streamingPageUrls = const <Uri>[],
    this.currentPage = 0,
    this.direction = ReaderDirection.ltr,
    this.readingMode = ReaderMode.single,
    this.autoDoublePage = false,
    this.thumbnailUrl,
    this.authorizationHeader,
  });

  final List<Uint8List> pages;
  final List<Uri> streamingPageUrls;
  final int currentPage;
  final ReaderDirection direction;
  final ReaderMode readingMode;
  final bool autoDoublePage;
  final String? thumbnailUrl;
  final String? authorizationHeader;

  bool get isStreaming => streamingPageUrls.isNotEmpty;

  int get pageCount => isStreaming ? streamingPageUrls.length : pages.length;

  int displayIndexForLogical(int logicalIndex) {
    if (direction == ReaderDirection.ltr) {
      return logicalIndex;
    }
    return pageCount - 1 - logicalIndex;
  }

  int logicalIndexForDisplay(int displayIndex) {
    if (direction == ReaderDirection.ltr) {
      return displayIndex;
    }
    return pageCount - 1 - displayIndex;
  }

  ReaderState copyWith({
    List<Uint8List>? pages,
    List<Uri>? streamingPageUrls,
    int? currentPage,
    ReaderDirection? direction,
    ReaderMode? readingMode,
    bool? autoDoublePage,
    String? thumbnailUrl,
    bool clearThumbnailUrl = false,
    String? authorizationHeader,
    bool clearAuthorizationHeader = false,
  }) {
    return ReaderState(
      pages: pages ?? this.pages,
      streamingPageUrls: streamingPageUrls ?? this.streamingPageUrls,
      currentPage: currentPage ?? this.currentPage,
      direction: direction ?? this.direction,
      readingMode: readingMode ?? this.readingMode,
      autoDoublePage: autoDoublePage ?? this.autoDoublePage,
      thumbnailUrl: clearThumbnailUrl ? null : (thumbnailUrl ?? this.thumbnailUrl),
      authorizationHeader: clearAuthorizationHeader
          ? null
          : (authorizationHeader ?? this.authorizationHeader),
    );
  }
}

class ReaderController extends StateNotifier<AsyncValue<ReaderState>> {
  ReaderController({
    required this.request,
    required ServerRepository repository,
    required ComicDownloader downloader,
    required ReadProgressRepository progressRepository,
    required DownloadRepository downloadRepository,
    required PageCacheManager pageCacheManager,
    required PseClient pseClient,
    required DivinaClient divinaClient,
    required ReaderDirection defaultDirection,
    required Map<int, ReadingDirectionPreference> serverReadingDirections,
  })  : _repository = repository,
        _downloader = downloader,
        _progressRepository = progressRepository,
        _downloadRepository = downloadRepository,
      _pageCacheManager = pageCacheManager,
        _pseClient = pseClient,
        _divinaClient = divinaClient,
        _defaultDirection = defaultDirection,
        _serverReadingDirections = serverReadingDirections,
        super(const AsyncValue.loading()) {
    _load();
  }

  final ReaderRequest request;
  final ServerRepository _repository;
  final ComicDownloader _downloader;
  final ReadProgressRepository _progressRepository;
  final DownloadRepository _downloadRepository;
  final PageCacheManager _pageCacheManager;
  final PseClient _pseClient;
  final DivinaClient _divinaClient;
  final ReaderDirection _defaultDirection;
  final Map<int, ReadingDirectionPreference> _serverReadingDirections;

  int? _serverId;
  final Set<String> _prefetchInFlight = <String>{};

  Future<void> _load() async {
    try {
      final servers = await _repository.watchAllServers().first;
      if (servers.isEmpty) {
        throw Exception('No OPDS server configured.');
      }

      final server = _resolveServerForRequest(servers);
      _serverId = server.id;
      final password = await _repository.getPassword(server.id);
      final authHeader = _buildAuthorizationHeader(
        username: server.username,
        password: password,
      );

      final streamingPageUrls = await _tryLoadStreamingPageUris(
        username: server.username,
        password: password,
      );

      List<Uint8List> pages = const <Uint8List>[];
      if (streamingPageUrls == null) {
        pages = await _loadArchivePages(
          serverId: server.id,
          publicationUrl: request.publicationUrl,
          username: server.username,
          password: password,
        );
      }

      final savedPage = await _progressRepository.getSavedPage(
        serverId: server.id,
        publicationUrl: request.publicationUrl,
      );
      final pageCount = streamingPageUrls?.length ?? pages.length;
      final clampedPage = savedPage == null ? 0 : savedPage.clamp(0, pageCount - 1);

      if (!mounted) {
        return;
      }

      final serverDirection = _serverReadingDirections[server.id] ==
              ReadingDirectionPreference.rtl
          ? ReaderDirection.rtl
          : _serverReadingDirections[server.id] == ReadingDirectionPreference.ltr
          ? ReaderDirection.ltr
          : _defaultDirection;

      state = AsyncValue.data(
        ReaderState(
          pages: pages,
          streamingPageUrls: streamingPageUrls ?? const <Uri>[],
          currentPage: clampedPage,
          direction: serverDirection,
          readingMode: ReadingModePreset.readingModeFromRaw(server.defaultReadingMode),
          autoDoublePage: server.autoDoublePage,
          thumbnailUrl: request.thumbnailUrl,
          authorizationHeader: authHeader,
        ),
      );

      _prefetchAround(clampedPage);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Uri>?> _tryLoadStreamingPageUris({
    String? username,
    String? password,
  }) async {
    final divinaStreamUrl = request.divinaManifestUrl;
    if ((divinaStreamUrl ?? '').isNotEmpty) {
      final divinaPages = await _tryLoadDivinaPages(
        Uri.parse(divinaStreamUrl!),
        username: username,
        password: password,
      );
      if (divinaPages != null) {
        if (divinaPages.isNotEmpty) {
          return divinaPages;
        }
      }
    }

    final pseStreamUrl = request.pseStreamUrl;
    if ((pseStreamUrl ?? '').isNotEmpty) {
      final psePages = await _tryLoadPsePages(
        Uri.parse(pseStreamUrl!),
        username: username,
        password: password,
      );
      if (psePages != null) {
        if (psePages.isNotEmpty) {
          return psePages;
        }
      }
    }

    return null;
  }

  Future<List<Uri>?> _tryLoadDivinaPages(
    Uri manifestUri, {
    String? username,
    String? password,
  }) async {
    try {
      final manifest = await _divinaClient.fetchManifest(
        manifestUri,
        username: username,
        password: password,
      );
      return manifest.pages.map((p) => manifestUri.resolve(p.href)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Uri>?> _tryLoadPsePages(
    Uri pseUri, {
    String? username,
    String? password,
  }) async {
    try {
      final feed = await _pseClient.fetchPages(
        pseUri,
        username: username,
        password: password,
      );
      return feed.pages.map((p) => pseUri.resolve(p.href)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Uint8List>> _loadArchivePages({
    required int serverId,
    required String publicationUrl,
    String? username,
    String? password,
  }) async {
    final existingDownload = await _downloadRepository.findByServerAndUrl(
      serverId: serverId,
      publicationUrl: publicationUrl,
    );

    List<int> archiveBytes;
    if (existingDownload != null &&
        existingDownload.status == 'complete' &&
        existingDownload.filePath != null &&
        existingDownload.filePath!.isNotEmpty) {
      final localFile = File(existingDownload.filePath!);
      if (await localFile.exists()) {
        archiveBytes = await localFile.readAsBytes();
      } else {
        archiveBytes = await _downloader.downloadBytes(
          Uri.parse(publicationUrl),
          username: username,
          password: password,
        );
      }
    } else {
      archiveBytes = await _downloader.downloadBytes(
        Uri.parse(publicationUrl),
        username: username,
        password: password,
      );
    }

    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final imageFiles = archive.files
        .where((f) => f.isFile && _isImageFile(f.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (imageFiles.isEmpty) {
      throw Exception('No images found in archive.');
    }

    return imageFiles.map((f) => Uint8List.fromList(f.content as List<int>)).toList();
  }

  ServerRecord _resolveServerForRequest(List<ServerRecord> servers) {
    final candidates = <String>[
      request.publicationUrl,
      if ((request.pseStreamUrl ?? '').isNotEmpty) request.pseStreamUrl!,
      if ((request.divinaManifestUrl ?? '').isNotEmpty)
        request.divinaManifestUrl!,
    ];

    ServerRecord? bestMatch;
    var bestScore = -1;

    for (final server in servers) {
      final serverUrl = server.url;
      for (final candidate in candidates) {
        if (candidate.startsWith(serverUrl) && serverUrl.length > bestScore) {
          bestMatch = server;
          bestScore = serverUrl.length;
        }
      }
    }

    if (bestMatch != null) {
      return bestMatch;
    }

    final publicationUri = Uri.tryParse(request.publicationUrl);
    if (publicationUri != null) {
      for (final server in servers) {
        final serverUri = Uri.tryParse(server.url);
        if (serverUri != null &&
            serverUri.host == publicationUri.host &&
            serverUri.scheme == publicationUri.scheme) {
          return server;
        }
      }
    }

    return servers.first;
  }



  void setDisplayPage(int displayIndex) {
    final current = state.valueOrNull;
    if (current == null || displayIndex < 0 || displayIndex >= current.pageCount) {
      return;
    }

    final logicalIndex = current.logicalIndexForDisplay(displayIndex);
    _setCurrentPage(current, logicalIndex);
    _prefetchAround(logicalIndex);
  }

  void setPage(int index) {
    final current = state.valueOrNull;
    if (current == null || index < 0 || index >= current.pageCount) {
      return;
    }
    _setCurrentPage(current, index);
    _prefetchAround(index);
  }

  void _prefetchAround(int index) {
    final current = state.valueOrNull;
    if (current == null || !current.isStreaming || current.streamingPageUrls.isEmpty) {
      return;
    }

    const radius = 2;
    final start = (index - radius).clamp(0, current.streamingPageUrls.length - 1);
    final end = (index + radius).clamp(0, current.streamingPageUrls.length - 1);

    _pageCacheManager.evictOutsideWindow(
      pageUris: current.streamingPageUrls,
      centerIndex: index,
      radius: radius,
    );

    for (var i = start; i <= end; i += 1) {
      final pageUri = current.streamingPageUrls[i];
      final key = pageUri.toString();
      if (_pageCacheManager.contains(key) || _prefetchInFlight.contains(key)) {
        continue;
      }
      _prefetchInFlight.add(key);
      _enqueuePrefetch(pageUri: pageUri, authHeader: current.authorizationHeader);
    }

    _logPrefetchMetrics(
      centerIndex: index,
      windowStart: start,
      windowEnd: end,
      pageCount: current.streamingPageUrls.length,
    );
  }

  void _enqueuePrefetch({
    required Uri pageUri,
    required String? authHeader,
  }) {
    unawaited(() async {
      try {
        final data = await _downloader.prefetchBytes(
          pageUri,
          headers: authHeader == null
              ? null
              : <String, String>{'Authorization': authHeader},
        );
        if (data != null && data.isNotEmpty) {
          _pageCacheManager.put(pageUri.toString(), Uint8List.fromList(data));
        }
      } finally {
        _prefetchInFlight.remove(pageUri.toString());
      }
    }());
  }

  void _logPrefetchMetrics({
    required int centerIndex,
    required int windowStart,
    required int windowEnd,
    required int pageCount,
  }) {
    assert(() {
      // Debug-only metrics for Phase 5 tuning.
      final windowSize = windowEnd - windowStart + 1;
      final ratio = pageCount == 0 ? 0 : (windowSize / pageCount);
      // ignore: avoid_print
      print(
        '[ReaderPrefetch] center=$centerIndex window=[$windowStart,$windowEnd] '
        'cached=${_pageCacheManager.count} bytes=${_pageCacheManager.currentBytes} '
        'coverage=${(ratio * 100).toStringAsFixed(1)}%',
      );
      return true;
    }());
  }

  void toggleDirection() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final nextDirection = current.direction == ReaderDirection.ltr
        ? ReaderDirection.rtl
        : ReaderDirection.ltr;

    state = AsyncValue.data(current.copyWith(direction: nextDirection));
  }

  void setReadingMode(ReaderMode mode) {
    final current = state.valueOrNull;
    if (current == null || current.readingMode == mode) {
      return;
    }

    state = AsyncValue.data(current.copyWith(readingMode: mode));
  }

  void _setCurrentPage(ReaderState current, int index) {
    state = AsyncValue.data(current.copyWith(currentPage: index));
    final serverId = _serverId;
    if (serverId == null) {
      return;
    }

    unawaited(
      _progressRepository.saveProgress(
        serverId: serverId,
        publicationUrl: request.publicationUrl,
        currentPage: index,
        totalPages: current.pageCount,
      ),
    );
  }

  static bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  String? _buildAuthorizationHeader({
    String? username,
    String? password,
  }) {
    final headers = buildBasicAuthHeaders(username: username, password: password);
    return headers['Authorization'];
  }
}
