import 'package:comicrow/core/network/http_transport.dart';
import 'package:comicrow/core/opds/pse_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransport implements HttpTransport {
  _FakeTransport(this.response);

  final HttpTextResponse response;

  @override
  Future<HttpTextResponse> get(
    Uri uri, {
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    return response;
  }
}

void main() {
  group('PseClient.parseFeed', () {
    test('parses entry links as ordered page list', () {
      const xml = '''
      <feed xmlns="http://www.w3.org/2005/Atom">
        <entry><link href="/pages/001.jpg" /></entry>
        <entry><link href="/pages/002.jpg" /></entry>
        <entry><link href="/pages/003.jpg" /></entry>
      </feed>
      ''';

      final doc = PseClient().parseFeed(xml);
      expect(doc.pages, hasLength(3));
      expect(doc.pages.first.href, '/pages/001.jpg');
      expect(doc.pages.first.index, 0);
      expect(doc.pages.last.href, '/pages/003.jpg');
      expect(doc.pages.last.index, 2);
    });

    test('throws when no page links are present', () {
      const xml = '<feed xmlns="http://www.w3.org/2005/Atom"></feed>';
      expect(() => PseClient().parseFeed(xml), throwsA(isA<PseException>()));
    });
  });

  group('PseClient.fetchPages', () {
    test('throws for non-success status', () async {
      final client = PseClient(
        transport: _FakeTransport(
          const HttpTextResponse(statusCode: 401, body: '<feed></feed>'),
        ),
      );

      expect(
        () => client.fetchPages(Uri.parse('https://example.com/pse')),
        throwsA(isA<PseException>()),
      );
    });
  });
}
