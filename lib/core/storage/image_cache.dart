import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final imageCacheStoreProvider = Provider<ImageCacheStore>((ref) {
  return ImageCacheStore();
});

class ImageCacheStore {
  ImageCacheStore({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, Uint8List> _memoryCache = <String, Uint8List>{};
  final Map<String, Future<Uint8List?>> _inflight = <String, Future<Uint8List?>>{};

  void clearMemory() {
    _memoryCache.clear();
    _inflight.clear();
  }

  Future<Uint8List?> getThumbnailBytes(
    String imageUrl, {
    Map<String, String>? headers,
  }) {
    final inMemory = _memoryCache[imageUrl];
    if (inMemory != null) {
      return Future.value(inMemory);
    }

    final inflight = _inflight[imageUrl];
    if (inflight != null) {
      return inflight;
    }

    final future = _loadAndCache(imageUrl, headers: headers);
    _inflight[imageUrl] = future;
    return future.whenComplete(() {
      _inflight.remove(imageUrl);
    });
  }

  Future<void> warmThumbnails(
    Iterable<String> imageUrls, {
    Map<String, String>? headers,
  }) async {
    for (final imageUrl in imageUrls) {
      await getThumbnailBytes(imageUrl, headers: headers);
    }
  }

  Future<Uint8List?> _loadAndCache(
    String imageUrl, {
    Map<String, String>? headers,
  }) async {
    try {
      final cacheFile = await _cacheFileForUrl(imageUrl);
      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        final data = Uint8List.fromList(bytes);
        _memoryCache[imageUrl] = data;
        return data;
      }

      final response = await _dio.getUri<List<int>>(
        Uri.parse(imageUrl),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
      );
      final payload = response.data;
      if (payload == null || payload.isEmpty) {
        return null;
      }

      final bytes = Uint8List.fromList(payload);
      _memoryCache[imageUrl] = bytes;
      await cacheFile.writeAsBytes(bytes, flush: true);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<File> _cacheFileForUrl(String imageUrl) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}${Platform.pathSeparator}comicrow_thumb_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final encoded = base64UrlEncode(utf8.encode(imageUrl));
    final fileName = encoded.replaceAll('=', '');
    return File('${cacheDir.path}${Platform.pathSeparator}$fileName.bin');
  }
}
