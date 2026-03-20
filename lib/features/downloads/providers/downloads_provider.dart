import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/database.dart';
import '../../../features/reader/data/comic_downloader.dart';
import '../../servers/data/server_repository.dart';
import '../data/download_repository.dart';

final downloadControllerProvider = Provider<DownloadController>((ref) {
  return DownloadController(
    repository: ref.watch(downloadRepositoryProvider),
    serverRepository: ref.watch(serverRepositoryProvider),
    downloader: ref.watch(comicDownloaderProvider),
  );
});

class DownloadController {
  DownloadController({
    required DownloadRepository repository,
    required ServerRepository serverRepository,
    required ComicDownloader downloader,
  })  : _repository = repository,
        _serverRepository = serverRepository,
        _downloader = downloader;

  final DownloadRepository _repository;
  final ServerRepository _serverRepository;
  final ComicDownloader _downloader;

  Future<void> enqueueDownload({
    required Uri publicationUri,
    required String title,
    String? thumbnailUrl,
  }) async {
    final servers = await _serverRepository.watchAllServers().first;
    if (servers.isEmpty) {
      throw Exception('No server configured for download.');
    }

    final server = _resolveServerForUri(servers, publicationUri);
    final queued = await _repository.upsertQueued(
      serverId: server.id,
      publicationUrl: publicationUri.toString(),
      title: title,
      thumbnailUrl: thumbnailUrl,
    );

    await _repository.markDownloading(queued.id);

    try {
      final password = await _serverRepository.getPassword(server.id);
      final bytes = await _downloader.downloadBytes(
        publicationUri,
        username: server.username,
        password: password,
      );

      final filePath = await _writeDownloadFile(publicationUri, bytes);
      await _repository.markComplete(
        id: queued.id,
        filePath: filePath,
        fileSize: bytes.length,
      );
    } catch (_) {
      await _repository.markFailed(queued.id);
      rethrow;
    }
  }

  Future<void> deleteDownload(int id) async {
    final active = await _repository.watchByStatuses(
      const ['complete', 'failed', 'queued', 'downloading'],
    ).first;

    final match = active.where((item) => item.id == id).firstOrNull;
    if (match != null && match.filePath != null && match.filePath!.isNotEmpty) {
      final file = File(match.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await _repository.deleteById(id);
  }

  Future<String> _writeDownloadFile(Uri uri, List<int> bytes) async {
    final dir = await _resolveDownloadDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName = _buildFileName(uri);
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final sharedDownloads = await getDownloadsDirectory();
    if (sharedDownloads != null) {
      return Directory(sharedDownloads.path);
    }

    if (Platform.isAndroid) {
      final externalDirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      final firstExternal = externalDirs?.firstOrNull;
      if (firstExternal != null) {
        return Directory(firstExternal.path);
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/downloads');
  }

  ServerRecord _resolveServerForUri(List<ServerRecord> servers, Uri publicationUri) {
    return servers.where((server) => publicationUri.toString().startsWith(server.url)).fold<ServerRecord?>(
          null,
          (best, server) {
            if (best == null || server.url.length > best.url.length) {
              return server;
            }
            return best;
          },
        ) ??
        servers.first;
  }

  String _buildFileName(Uri uri) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final segments = uri.pathSegments;
    final base = segments.isEmpty ? 'comic' : segments.last;
    return '${now}_$base';
  }
}