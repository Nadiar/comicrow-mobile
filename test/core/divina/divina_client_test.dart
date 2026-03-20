import 'package:comicrow/core/network/http_transport.dart';
import 'package:comicrow/core/divina/divina_client.dart';
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
  group('DivinaClient.parseManifest', () {
    test('parses title and readingOrder pages', () {
      const json = '''
      {
        "metadata": {"title": "Saga"},
        "readingOrder": [
          {"href": "/img/001.jpg", "type": "image/jpeg", "width": 1200, "height": 1800},
          {"href": "/img/002.jpg", "type": "image/jpeg"}
        ]
      }
      ''';

      final manifest = DivinaClient().parseManifest(json);
      expect(manifest.title, 'Saga');
      expect(manifest.pages, hasLength(2));
      expect(manifest.pages.first.href, '/img/001.jpg');
      expect(manifest.pages.first.index, 0);
      expect(manifest.pages.first.width, 1200);
    });

    test('throws when readingOrder missing', () {
      const json = '{"metadata": {"title": "Saga"}}';
      expect(
        () => DivinaClient().parseManifest(json),
        throwsA(isA<DivinaException>()),
      );
    });
  });

  group('DivinaClient.fetchManifest', () {
    test('throws on non-success status', () async {
      final client = DivinaClient(
        transport: _FakeTransport(
          const HttpTextResponse(statusCode: 500, body: '{}'),
        ),
      );

      expect(
        () => client.fetchManifest(Uri.parse('https://example.com/manifest')),
        throwsA(isA<DivinaException>()),
      );
    });
  });
}
