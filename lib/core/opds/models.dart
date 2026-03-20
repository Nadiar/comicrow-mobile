import 'opds_client.dart';

enum OpdsEntryKind { navigation, publication }

class OpdsEntry {
  const OpdsEntry({
    required this.title,
    required this.href,
    required this.kind,
    this.thumbnailHref,
    this.summary,
    this.pseStreamHref,
    this.divinaManifestHref,
  });

  final String title;
  final String href;
  final OpdsEntryKind kind;
  final String? thumbnailHref;
  final String? summary;
  final String? pseStreamHref;
  final String? divinaManifestHref;
}

class OpdsFeed {
  const OpdsFeed({
    required this.version,
    required this.title,
    required this.entries,
    this.nextHref,
    this.searchUrl,
  });

  final OpdsVersion version;
  final String title;
  final List<OpdsEntry> entries;
  final String? nextHref;
  final String? searchUrl;

  OpdsFeed copyWith({
    OpdsVersion? version,
    String? title,
    List<OpdsEntry>? entries,
    String? nextHref,
    String? searchUrl,
    bool clearSearchUrl = false,
    bool clearNextHref = false,
  }) {
    return OpdsFeed(
      version: version ?? this.version,
      title: title ?? this.title,
      entries: entries ?? this.entries,
      nextHref: clearNextHref ? null : (nextHref ?? this.nextHref),
      searchUrl: clearSearchUrl ? null : (searchUrl ?? this.searchUrl),
    );
  }
}
