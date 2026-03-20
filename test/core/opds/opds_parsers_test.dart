import 'package:comicrow/core/opds/models.dart';
import 'package:comicrow/core/opds/opds_client.dart';
import 'package:comicrow/core/opds/opds1_parser.dart';
import 'package:comicrow/core/opds/opds2_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Opds1Parser.parseFeed', () {
    test('parses feed title and entries from atom xml', () {
      const xml = '''
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Comic Catalog</title>
        <link rel="next" href="/next.xml" />
        <link rel="search" href="/search{?searchTerms}" />
        <entry>
          <title>Batman Vol 1</title>
          <summary>Detective comics arc</summary>
          <link rel="http://opds-spec.org/acquisition" href="/books/batman.cbz" type="application/vnd.comicbook+zip" />
          <link rel="http://vaemendis.net/opds-pse/stream" href="/pse/pages?path=batman" type="application/atom+xml" />
          <link rel="http://opds-spec.org/image/thumbnail" href="/covers/batman.jpg" />
        </entry>
      </feed>
      ''';

      final feed = const Opds1Parser().parseFeed(xml);

      expect(feed.version, OpdsVersion.opds1);
      expect(feed.title, 'Comic Catalog');
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.title, 'Batman Vol 1');
      expect(feed.entries.first.href, '/books/batman.cbz');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
      expect(feed.entries.first.thumbnailHref, '/covers/batman.jpg');
      expect(feed.entries.first.summary, 'Detective comics arc');
      expect(feed.entries.first.pseStreamHref, '/pse/pages?path=batman');
      expect(feed.nextHref, '/next.xml');
      expect(feed.searchUrl, '/search{?searchTerms}');
    });

    test('includes non-CBZ acquisition entries', () {
      const xml = '''
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Comic Catalog</title>
        <entry>
          <title>EPUB Book</title>
          <link rel="http://opds-spec.org/acquisition" href="/books/epub-only.epub" type="application/epub+zip" />
        </entry>
      </feed>
      ''';

      final feed = const Opds1Parser().parseFeed(xml);
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.href, '/books/epub-only.epub');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
    });

    test('falls back to non-image publication link when acquisition rel is missing', () {
      const xml = '''
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Comic Catalog</title>
        <entry>
          <title>CBZ Without Acquisition Rel</title>
          <link rel="http://opds-spec.org/image/thumbnail" href="/covers/no-rel.jpg" type="image/jpeg" />
          <link href="/pubs/no-rel.cbz" type="application/vnd.comicbook+zip" />
        </entry>
      </feed>
      ''';

      final feed = const Opds1Parser().parseFeed(xml);
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.href, '/pubs/no-rel.cbz');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
    });
  });

  group('Opds2Parser.parseFeed', () {
    test('parses feed title and publications from opds json', () {
      const json = '''
      {
        "metadata": {"title": "My OPDS2"},
        "links": [
          {"rel": "next", "href": "/page/2"},
          {"rel": "search", "href": "/search{?searchTerms}"}
        ],
        "publications": [
          {
            "metadata": {"title": "Saga #1", "description": "Issue 1"},
            "links": [
              {"href": "/v2/manifest?path=saga-1", "type": "application/divina+json", "rel": "self"},
              {"href": "/pubs/saga-1.epub", "type": "application/epub+zip"},
              {"href": "/pubs/saga-1.cbz", "type": "application/vnd.comicbook+zip"},
              {"rel": "cover", "href": "/covers/saga-1.jpg"}
            ]
          }
        ],
        "navigation": [
          {
            "metadata": {"title": "By Author"},
            "links": [{"href": "/nav/authors"}]
          }
        ]
      }
      ''';

      final feed = const Opds2Parser().parseFeed(json);

      expect(feed.version, OpdsVersion.opds2);
      expect(feed.title, 'My OPDS2');
      expect(feed.entries, hasLength(2));
      expect(feed.entries.first.title, 'Saga #1');
      expect(feed.entries.first.href, '/pubs/saga-1.epub');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
      expect(feed.entries.first.thumbnailHref, '/covers/saga-1.jpg');
      expect(feed.entries.first.summary, 'Issue 1');
      expect(feed.entries.first.divinaManifestHref, '/v2/manifest?path=saga-1');
      expect(feed.entries.last.kind, OpdsEntryKind.navigation);
      expect(feed.nextHref, '/page/2');
      expect(feed.searchUrl, '/search{?searchTerms}');
    });

    test('includes epub-only publication entries', () {
      const json = '''
      {
        "metadata": {"title": "My OPDS2"},
        "publications": [
          {
            "metadata": {"title": "EPUB Only"},
            "links": [{"href": "/pubs/epub-only.epub", "type": "application/epub+zip"}]
          }
        ]
      }
      ''';

      final feed = const Opds2Parser().parseFeed(json);
      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.href, '/pubs/epub-only.epub');
      expect(feed.entries.first.kind, OpdsEntryKind.publication);
    });

    test('parses compact navigation items and grouped feeds', () {
      const json = '''
      {
        "metadata": {"title": "Library"},
        "navigation": [
          {
            "title": "Smart Lists",
            "href": "/opds/smart",
            "type": "application/opds+json",
            "rel": "subsection"
          }
        ],
        "groups": [
          {
            "metadata": {"title": "Featured"},
            "publications": [
              {
                "title": "Saga #1",
                "href": "/pubs/saga-1.cbz",
                "summary": "Issue 1"
              }
            ]
          }
        ]
      }
      ''';

      final feed = const Opds2Parser().parseFeed(json);

      expect(feed.entries, hasLength(2));
      expect(feed.entries[0].kind, OpdsEntryKind.publication);
      expect(feed.entries[0].title, 'Saga #1');
      expect(feed.entries[0].href, '/pubs/saga-1.cbz');
      expect(feed.entries[1].kind, OpdsEntryKind.navigation);
      expect(feed.entries[1].title, 'Smart Lists');
      expect(feed.entries[1].href, '/opds/smart');
    });

    test('reads thumbnail from images array used by smart list publications', () {
      const json = '''
      {
        "metadata": {"title": "Smart List"},
        "publications": [
          {
            "metadata": {"title": "Absolute Batman #1"},
            "links": [
              {
                "rel": "http://opds-spec.org/acquisition/open-access",
                "href": "/book/1/download",
                "type": "application/vnd.comicbook+zip"
              }
            ],
            "images": [
              {
                "rel": "http://opds-spec.org/image/thumbnail",
                "href": "/book/1/thumb",
                "type": "image/jpeg"
              }
            ]
          }
        ]
      }
      ''';

      final feed = const Opds2Parser().parseFeed(json);

      expect(feed.entries, hasLength(1));
      expect(feed.entries.first.title, 'Absolute Batman #1');
      expect(feed.entries.first.thumbnailHref, '/book/1/thumb');
    });

    test('parses links-only directory feeds when publications/navigation are absent', () {
      const json = '''
      {
        "metadata": {"title": "/DC Comics/Absolute Batman"},
        "links": [
          {"rel": "self", "href": "/opds/folder"},
          {
            "rel": "subsection",
            "title": "Volume 1",
            "href": "/opds/folder/vol-1",
            "type": "application/opds+json"
          },
          {
            "rel": "http://opds-spec.org/acquisition/open-access",
            "title": "Absolute Batman #1",
            "href": "/opds/download/ab-1.cbz",
            "type": "application/vnd.comicbook+zip"
          }
        ]
      }
      ''';

      final feed = const Opds2Parser().parseFeed(json);
      expect(feed.title, '/DC Comics/Absolute Batman');
      expect(feed.entries, hasLength(2));
      expect(feed.entries[0].kind, OpdsEntryKind.navigation);
      expect(feed.entries[0].title, 'Volume 1');
      expect(feed.entries[1].kind, OpdsEntryKind.publication);
      expect(feed.entries[1].href, '/opds/download/ab-1.cbz');
    });
  });
}
