import 'dart:typed_data';

import 'package:comicrow/features/reader/services/page_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(int size) => Uint8List.fromList(List<int>.generate(size, (i) => i % 255));

void main() {
  group('PageCacheManager', () {
    test('evicts least-recently-used items when over budget', () {
      final cache = PageCacheManager(maxBytes: 10);

      cache.put('a', _bytes(4));
      cache.put('b', _bytes(4));
      cache.put('c', _bytes(4));

      expect(cache.contains('a'), isFalse);
      expect(cache.contains('b'), isTrue);
      expect(cache.contains('c'), isTrue);
      expect(cache.currentBytes, lessThanOrEqualTo(10));
    });

    test('evictOutsideWindow keeps only nearby pages', () {
      final cache = PageCacheManager(maxBytes: 1000);
      final pages = <Uri>[];
      for (var i = 0; i < 6; i += 1) {
        final uri = Uri.parse('https://example.com/p$i.jpg');
        pages.add(uri);
        cache.put(uri.toString(), _bytes(8));
      }

      cache.evictOutsideWindow(
        pageUris: pages,
        centerIndex: 3,
        radius: 1,
      );

      expect(cache.contains('https://example.com/p2.jpg'), isTrue);
      expect(cache.contains('https://example.com/p3.jpg'), isTrue);
      expect(cache.contains('https://example.com/p4.jpg'), isTrue);
      expect(cache.contains('https://example.com/p0.jpg'), isFalse);
      expect(cache.contains('https://example.com/p5.jpg'), isFalse);
    });

    test('clear empties cache and resets byte count', () {
      final cache = PageCacheManager(maxBytes: 1000);
      cache.put('a', _bytes(100));
      cache.put('b', _bytes(200));

      expect(cache.count, 2);
      expect(cache.currentBytes, 300);

      cache.clear();

      expect(cache.count, 0);
      expect(cache.currentBytes, 0);
      expect(cache.contains('a'), isFalse);
    });

    test('respects configured maxBytes budget', () {
      final smallCache = PageCacheManager(maxBytes: 20);
      smallCache.put('a', _bytes(10));
      smallCache.put('b', _bytes(10));
      smallCache.put('c', _bytes(10));

      expect(smallCache.currentBytes, lessThanOrEqualTo(20));
      expect(smallCache.contains('a'), isFalse);
      expect(smallCache.contains('b'), isTrue);
      expect(smallCache.contains('c'), isTrue);

      final largeCache = PageCacheManager(maxBytes: 100);
      largeCache.put('a', _bytes(10));
      largeCache.put('b', _bytes(10));
      largeCache.put('c', _bytes(10));

      expect(largeCache.currentBytes, 30);
      expect(largeCache.contains('a'), isTrue);
      expect(largeCache.contains('b'), isTrue);
      expect(largeCache.contains('c'), isTrue);
    });
  });
}
