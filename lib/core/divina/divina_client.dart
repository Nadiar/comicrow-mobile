import 'dart:convert';

import '../network/http_transport.dart';
import 'models.dart';

class DivinaException implements Exception {
  const DivinaException(this.message);

  final String message;

  @override
  String toString() => 'DivinaException: $message';
}

class DivinaClient {
  DivinaClient({HttpTransport? transport})
      : _transport = transport ?? DioHttpTransport();

  final HttpTransport _transport;

  Future<DivinaManifest> fetchManifest(
    Uri manifestUri, {
    String? username,
    String? password,
  }) async {
    final response = await _transport.get(
      manifestUri,
      username: username,
      password: password,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DivinaException(
        'DiViNa request failed with status ${response.statusCode}.',
      );
    }

    return parseManifest(response.body);
  }

  DivinaManifest parseManifest(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! Map<String, dynamic>) {
      throw const DivinaException('Invalid DiViNa manifest payload.');
    }

    final metadata = decoded['metadata'];
    final title = metadata is Map<String, dynamic>
        ? (metadata['title']?.toString() ?? 'Untitled')
        : 'Untitled';

    final readingOrder = decoded['readingOrder'];
    if (readingOrder is! List || readingOrder.isEmpty) {
      throw const DivinaException('DiViNa manifest has no readingOrder pages.');
    }

    final pages = <DivinaPage>[];
    var index = 0;
    for (final item in readingOrder) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final href = item['href']?.toString();
      if (href == null || href.isEmpty) {
        continue;
      }

      final width = _intOrNull(item['width']);
      final height = _intOrNull(item['height']);
      final type = item['type']?.toString();

      pages.add(
        DivinaPage(
          href: href,
          index: index,
          type: type,
          width: width,
          height: height,
        ),
      );
      index += 1;
    }

    if (pages.isEmpty) {
      throw const DivinaException('DiViNa manifest has no valid page URLs.');
    }

    return DivinaManifest(title: title, pages: pages);
  }

  int? _intOrNull(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
