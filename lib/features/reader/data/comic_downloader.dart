import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/auth.dart';

final comicDownloaderProvider = Provider<ComicDownloader>(
  (ref) => DioComicDownloader(),
);

abstract class ComicDownloader {
  Future<List<int>> downloadBytes(
    Uri uri, {
    String? username,
    String? password,
  });

  Future<List<int>> downloadBytesWithHeaders(
    Uri uri, {
    Map<String, String>? headers,
  });

  Future<List<int>?> prefetchBytes(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  });
}

class DioComicDownloader implements ComicDownloader {
  DioComicDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  Future<void> _prefetchQueue = Future<void>.value();

  @override
  Future<List<int>> downloadBytes(
    Uri uri, {
    String? username,
    String? password,
  }) async {
    final headers = _authHeaders(username: username, password: password);
    return _downloadBytes(uri, headers: headers);
  }

  @override
  Future<List<int>> downloadBytesWithHeaders(
    Uri uri, {
    Map<String, String>? headers,
  }) {
    return _downloadBytes(uri, headers: headers);
  }

  @override
  Future<List<int>?> prefetchBytes(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) {
    final completer = Completer<List<int>?>();
    _prefetchQueue = _prefetchQueue.then((_) async {
      try {
        final resolvedHeaders = headers ?? _authHeaders(username: username, password: password);
        final data = await _downloadBytes(uri, headers: resolvedHeaders);
        completer.complete(data);
      } catch (_) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<List<int>> _downloadBytes(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await _dio.getUri<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
    );

    if (response.data == null) {
      throw Exception('Empty response when downloading publication.');
    }
    return response.data!;
  }

  Map<String, String>? _authHeaders({
    String? username,
    String? password,
  }) {
    final headers = buildBasicAuthHeaders(username: username, password: password);
    return headers.isEmpty ? null : headers;
  }
}
