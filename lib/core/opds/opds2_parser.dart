import 'dart:convert';

import 'models.dart';
import 'opds_client.dart';

class Opds2Parser {
  const Opds2Parser();

  OpdsFeed parseFeed(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! Map<String, dynamic>) {
      return const OpdsFeed(
        version: OpdsVersion.opds2,
        title: 'Library',
        entries: [],
        nextHref: null,
      );
    }

    final metadata = decoded['metadata'];
    final title = metadata is Map<String, dynamic>
        ? (metadata['title']?.toString() ?? 'Library')
        : 'Library';

    final entries = <OpdsEntry>[];

    final publications = decoded['publications'];
    if (publications is List) {
      entries.addAll(_readItems(publications, kind: OpdsEntryKind.publication));
    }

    final groups = decoded['groups'];
    if (groups is List) {
      entries.addAll(_readGroupedItems(groups));
    }

    final navigation = decoded['navigation'];
    if (navigation is List) {
      entries.addAll(_readItems(navigation, kind: OpdsEntryKind.navigation));
    }

    final catalogs = decoded['catalogs'];
    if (catalogs is List) {
      entries.addAll(_readItems(catalogs, kind: OpdsEntryKind.navigation));
    }

    if (entries.isEmpty) {
      entries.addAll(_readEntriesFromTopLevelLinks(decoded['links']));
    }

    final nextHref = _pickNextHref(decoded['links']);
    final searchUrl = _pickSearchHref(decoded['links']);

    return OpdsFeed(
      version: OpdsVersion.opds2,
      title: title,
      entries: entries,
      nextHref: nextHref,
      searchUrl: searchUrl,
    );
  }

  List<OpdsEntry> _readGroupedItems(List groups) {
    final entries = <OpdsEntry>[];
    for (final group in groups) {
      if (group is! Map<String, dynamic>) {
        continue;
      }

      final groupPublications = group['publications'];
      if (groupPublications is List) {
        entries.addAll(_readItems(groupPublications, kind: OpdsEntryKind.publication));
      }

      final groupNavigation = group['navigation'];
      if (groupNavigation is List) {
        entries.addAll(_readItems(groupNavigation, kind: OpdsEntryKind.navigation));
      }
    }
    return entries;
  }

  List<OpdsEntry> _readItems(List items, {required OpdsEntryKind kind}) {
    final entries = <OpdsEntry>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final metadata = item['metadata'];
        final title = _entryTitle(item, metadata);

      final links = item['links'];
        final images = item['images'];
      final href = kind == OpdsEntryKind.publication
          ? _publicationHref(item, links)
          : _navigationHref(item, links);
        final thumbnailHref = _firstThumbnailHref(links, images);
      final divinaManifestHref = _firstDivinaHref(links);
        final summary = _entrySummary(item, metadata);

      if (href != null && href.isNotEmpty) {
        entries.add(
          OpdsEntry(
            title: title,
            href: href,
            kind: kind,
            thumbnailHref: thumbnailHref,
            summary: summary,
            divinaManifestHref: divinaManifestHref,
          ),
        );
      }
    }
    return entries;
  }

  String _entryTitle(
    Map<String, dynamic> item,
    Object? metadata,
  ) {
    if (metadata is Map<String, dynamic>) {
      final metaTitle = metadata['title']?.toString();
      if ((metaTitle ?? '').trim().isNotEmpty) {
        return metaTitle!.trim();
      }
    }

    final directTitle = item['title']?.toString();
    if ((directTitle ?? '').trim().isNotEmpty) {
      return directTitle!.trim();
    }

    return 'Untitled';
  }

  String? _entrySummary(
    Map<String, dynamic> item,
    Object? metadata,
  ) {
    final directSummary = item['summary']?.toString();
    if ((directSummary ?? '').trim().isNotEmpty) {
      return directSummary!.trim();
    }
    return _metadataSummary(metadata);
  }

  String? _navigationHref(
    Map<String, dynamic> item,
    Object? links,
  ) {
    final directHref = item['href']?.toString();
    if ((directHref ?? '').trim().isNotEmpty) {
      return directHref;
    }
    return _firstHref(links);
  }

  String? _publicationHref(
    Map<String, dynamic> item,
    Object? links,
  ) {
    final directHref = item['href']?.toString();
    if ((directHref ?? '').trim().isNotEmpty) {
      return directHref;
    }
    return _primaryPublicationHref(links);
  }

  String? _metadataSummary(Object? metadata) {
    if (metadata is! Map<String, dynamic>) {
      return null;
    }

    final value = metadata['description'] ?? metadata['subtitle'];
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    return text.trim();
  }

  String? _firstHref(Object? links) {
    if (links is! List || links.isEmpty) {
      return null;
    }
    final first = links.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }
    return first['href']?.toString();
  }

  String? _firstThumbnailHref(Object? links, Object? images) {
    final imageHref = _firstThumbnailHrefFromCollection(images);
    if (imageHref != null) {
      return imageHref;
    }

    return _firstThumbnailHrefFromCollection(links);
  }

  String? _firstThumbnailHrefFromCollection(Object? collection) {
    if (collection is! List || collection.isEmpty) {
      return null;
    }

    for (final item in collection) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final rel = item['rel'];
      final relValue = rel?.toString().toLowerCase() ?? '';
      if (relValue.contains('thumbnail')) {
        return item['href']?.toString();
      }
    }

    for (final item in collection) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final rel = item['rel'];
      final relValue = rel?.toString().toLowerCase() ?? '';
      if (relValue.contains('cover') || relValue.contains('image')) {
        return item['href']?.toString();
      }
    }

    return null;
  }

  String? _primaryPublicationHref(Object? links) {
    if (links is! List || links.isEmpty) {
      return null;
    }

    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final rel = item['rel']?.toString().toLowerCase() ?? '';
      if (rel.contains('acquisition') || rel.contains('open-access')) {
        return item['href']?.toString();
      }
    }

    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final type = item['type']?.toString().toLowerCase() ?? '';
      if (type.startsWith('image/')) {
        continue;
      }
      if (type.contains('divina+json')) {
        continue;
      }
      final href = item['href']?.toString();
      if (href != null && href.isNotEmpty) {
        return href;
      }
    }

    return _firstHref(links);
  }

  String? _firstDivinaHref(Object? links) {
    if (links is! List || links.isEmpty) {
      return null;
    }

    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final type = item['type']?.toString().toLowerCase() ?? '';
      if (type.contains('application/divina+json')) {
        return item['href']?.toString();
      }
    }

    return null;
  }

  String? _pickNextHref(Object? links) {
    if (links is! List || links.isEmpty) {
      return null;
    }

    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final rel = item['rel']?.toString().toLowerCase() ?? '';
      if (rel == 'next' || rel.contains('next')) {
        return item['href']?.toString();
      }
    }

    return null;
  }

  String? _pickSearchHref(Object? links) {
    if (links is! List || links.isEmpty) {
      return null;
    }

    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final rel = item['rel']?.toString().toLowerCase() ?? '';
      if (rel == 'search' || rel.contains('search')) {
        return item['href']?.toString();
      }
    }

    return null;
  }

  List<OpdsEntry> _readEntriesFromTopLevelLinks(Object? links) {
    if (links is! List || links.isEmpty) {
      return const <OpdsEntry>[];
    }

    final entries = <OpdsEntry>[];
    for (final item in links) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final href = item['href']?.toString();
      if ((href ?? '').trim().isEmpty) {
        continue;
      }

      final rel = item['rel']?.toString().toLowerCase() ?? '';
      if (rel == 'self' || rel.contains('next') || rel.contains('search') || rel.contains('start')) {
        continue;
      }

      final type = item['type']?.toString().toLowerCase() ?? '';
      final title = _entryTitleFromLink(item, href!);
      final kind = _entryKindFromLink(rel: rel, type: type);

      entries.add(
        OpdsEntry(
          title: title,
          href: href,
          kind: kind,
        ),
      );
    }

    return entries;
  }

  String _entryTitleFromLink(Map<String, dynamic> link, String href) {
    final title = link['title']?.toString();
    if ((title ?? '').trim().isNotEmpty) {
      return title!.trim();
    }

    final segment = Uri.tryParse(href)?.pathSegments.lastOrNull;
    if ((segment ?? '').trim().isNotEmpty) {
      return segment!;
    }

    return href;
  }

  OpdsEntryKind _entryKindFromLink({required String rel, required String type}) {
    if (rel.contains('acquisition') || rel.contains('open-access')) {
      return OpdsEntryKind.publication;
    }

    if (type.contains('comicbook') || type.contains('epub') || type.contains('pdf') || type.contains('zip')) {
      return OpdsEntryKind.publication;
    }

    return OpdsEntryKind.navigation;
  }
}