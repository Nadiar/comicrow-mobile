import 'package:comicrow/core/network/http_transport.dart';
import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/core/opds/models.dart';
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
  group('OpdsClient.detectVersion', () {
    test('returns opds2 for JSON response content type', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'application/opds+json',
            body: '{"metadata":{}}',
          ),
        ),
      );

      final result = await client.detectVersion(Uri.parse('https://example.com'));

      expect(result, OpdsVersion.opds2);
    });

    test('returns opds1 for XML response content type', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'application/atom+xml',
            body: '<feed></feed>',
          ),
        ),
      );

      final result = await client.detectVersion(Uri.parse('https://example.com'));

      expect(result, OpdsVersion.opds1);
    });

    test('falls back to body sniffing when content type is unknown', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'text/plain',
            body: '{"publications":[]}',
          ),
        ),
      );

      final result = await client.detectVersion(Uri.parse('https://example.com'));

      expect(result, OpdsVersion.opds2);
    });

    test('throws OpdsConnectionException for non-success status code', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 401,
            contentType: 'application/json',
            body: '{}',
          ),
        ),
      );

      expect(
        () => client.detectVersion(Uri.parse('https://example.com')),
        throwsA(isA<OpdsConnectionException>()),
      );
    });
  });

  group('OpdsClient.fetchRootFeed', () {
    test('parses opds2 feed payload', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'application/opds+json',
            body:
                '{"metadata":{"title":"Root"},"publications":[{"metadata":{"title":"Book"},"links":[{"href":"/book.epub","type":"application/epub+zip"},{"href":"/book.cbz","type":"application/vnd.comicbook+zip"}]}]}',
          ),
        ),
      );

      final feed = await client.fetchRootFeed(Uri.parse('https://example.com'));

      expect(feed.title, 'Root');
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.href, '/book.epub');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
    });

    test('parses opds1 feed payload', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'application/atom+xml',
            body:
                '<feed xmlns="http://www.w3.org/2005/Atom"><title>Root</title><entry><title>Book</title><link href="/book" /></entry></feed>',
          ),
        ),
      );

      final feed = await client.fetchRootFeed(Uri.parse('https://example.com'));

      expect(feed.title, 'Root');
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.href, '/book');
      expect(feed.entries.first.kind, OpdsEntryKind.navigation);
    });

    test('throws when format cannot be detected', () async {
      final client = OpdsClient(
        transport: _FakeTransport(
          const HttpTextResponse(
            statusCode: 200,
            contentType: 'text/plain',
            body: 'hello world',
          ),
        ),
      );

      expect(
        () => client.fetchRootFeed(Uri.parse('https://example.com')),
        throwsA(isA<OpdsConnectionException>()),
      );
    });
  });
}
