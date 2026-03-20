import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final pageCacheManagerProvider = Provider<PageCacheManager>((ref) {
  return PageCacheManager(maxBytes: 500 * 1024 * 1024);
});

class PageCacheManager {
  PageCacheManager({required this.maxBytes});

  int maxBytes;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap<String, Uint8List>();

  int _currentBytes = 0;

  int get currentBytes => _currentBytes;
  int get count => _cache.length;

  bool contains(String key) => _cache.containsKey(key);

  void clear() {
    _cache.clear();
    _currentBytes = 0;
  }

  Uint8List? get(String key) {
    final value = _cache.remove(key);
    if (value == null) {
      return null;
    }

    _cache[key] = value;
    return value;
  }

  void put(String key, Uint8List bytes) {
    final previous = _cache.remove(key);
    if (previous != null) {
      _currentBytes -= previous.lengthInBytes;
    }

    _cache[key] = bytes;
    _currentBytes += bytes.lengthInBytes;
    _evictToBudget();
  }

  void evictOutsideWindow({
    required List<Uri> pageUris,
    required int centerIndex,
    required int radius,
  }) {
    if (_cache.isEmpty || pageUris.isEmpty) {
      return;
    }

    final start = (centerIndex - radius).clamp(0, pageUris.length - 1);
    final end = (centerIndex + radius).clamp(0, pageUris.length - 1);
    final keepKeys = <String>{};
    for (var i = start; i <= end; i += 1) {
      keepKeys.add(pageUris[i].toString());
    }

    final keysToRemove = _cache.keys.where((k) => !keepKeys.contains(k)).toList();
    for (final key in keysToRemove) {
      final removed = _cache.remove(key);
      if (removed != null) {
        _currentBytes -= removed.lengthInBytes;
      }
    }
  }

  void _evictToBudget() {
    while (_currentBytes > maxBytes && _cache.isNotEmpty) {
      final firstKey = _cache.keys.first;
      final removed = _cache.remove(firstKey);
      if (removed != null) {
        _currentBytes -= removed.lengthInBytes;
      }
    }
  }
}
