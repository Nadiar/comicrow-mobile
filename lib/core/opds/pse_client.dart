import 'package:xml/xml.dart';

import '../network/http_transport.dart';

class PsePageLink {
  const PsePageLink({
    required this.href,
    required this.index,
  });

  final String href;
  final int index;
}

class PseDocument {
  const PseDocument({required this.pages});

  final List<PsePageLink> pages;
}

class PseException implements Exception {
  const PseException(this.message);

  final String message;

  @override
  String toString() => 'PseException: $message';
}

class PseClient {
  PseClient({HttpTransport? transport})
      : _transport = transport ?? DioHttpTransport();

  final HttpTransport _transport;

  Future<PseDocument> fetchPages(
    Uri pseUri, {
    String? username,
    String? password,
  }) async {
    final response = await _transport.get(
      pseUri,
      username: username,
      password: password,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PseException('PSE request failed with status ${response.statusCode}.');
    }

    return parseFeed(response.body);
  }

  PseDocument parseFeed(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);
    final pages = <PsePageLink>[];

    var index = 0;
    for (final entry in document.findAllElements('entry')) {
      final link = entry.findElements('link').firstOrNull;
      final href = link?.getAttribute('href');
      if (href == null || href.isEmpty) {
        continue;
      }
      pages.add(PsePageLink(href: href, index: index));
      index += 1;
    }

    if (pages.isEmpty) {
      throw const PseException('No page links found in PSE feed.');
    }

    return PseDocument(pages: pages);
  }
}
