import 'package:xml/xml.dart';

import 'models.dart';
import 'opds_client.dart';

class Opds1Parser {
  const Opds1Parser();

  OpdsFeed parseFeed(String xmlBody) {
    final document = XmlDocument.parse(xmlBody);
    final feed = document.findAllElements('feed').firstOrNull;
    final title =
        feed?.findElements('title').firstOrNull?.innerText.trim() ??
        'Library';

    final entries = <OpdsEntry>[];
    for (final entry in document.findAllElements('entry')) {
      final entryTitle =
          entry.findElements('title').firstOrNull?.innerText.trim() ??
          'Untitled';
      final links = entry.findElements('link').toList();
      final kind = _detectKind(links);
      final href = _pickPrimaryHref(links, kind: kind);
      final thumbnailHref = _pickThumbnailHref(links);
        final pseStreamHref = _pickPseStreamHref(links);
      final summary =
          entry.findElements('summary').firstOrNull?.innerText.trim() ??
          entry.findElements('content').firstOrNull?.innerText.trim();

      if (href.isNotEmpty) {
        entries.add(
          OpdsEntry(
            title: entryTitle,
            href: href,
            kind: kind,
            thumbnailHref: thumbnailHref,
            summary: summary?.isEmpty == true ? null : summary,
            pseStreamHref: pseStreamHref,
          ),
        );
      }
    }

    final feedLinks = feed?.findElements('link').toList() ?? [];
    final nextHref = _pickNextHref(feedLinks);
    final searchUrl = _pickSearchHref(feedLinks);

    return OpdsFeed(
      version: OpdsVersion.opds1,
      title: title,
      entries: entries,
      nextHref: nextHref,
      searchUrl: searchUrl,
    );
  }

  String _pickPrimaryHref(List<XmlElement> links, {required OpdsEntryKind kind}) {
    if (kind == OpdsEntryKind.publication) {
      for (final link in links) {
        final rel = (link.getAttribute('rel') ?? '').toLowerCase();
        if (rel.contains('acquisition') || rel.contains('/open-access')) {
          return link.getAttribute('href') ?? '';
        }
      }

      for (final link in links) {
        final type = (link.getAttribute('type') ?? '').toLowerCase();
        if (type.startsWith('image/')) {
          continue;
        }
        final href = link.getAttribute('href') ?? '';
        if (href.isNotEmpty) {
          return href;
        }
      }

      return '';
    }

    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (!rel.contains('acquisition') && !rel.contains('/open-access')) {
        return link.getAttribute('href') ?? '';
      }
    }

    return '';
  }

  String? _pickThumbnailHref(List<XmlElement> links) {
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (rel.contains('thumbnail') || rel.contains('/image')) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  String? _pickNextHref(List<XmlElement> links) {
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (rel == 'next' || rel.contains('next')) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  String? _pickSearchHref(List<XmlElement> links) {
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (rel == 'search' || rel.contains('search')) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  String? _pickPseStreamHref(List<XmlElement> links) {
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (rel.contains('vaemendis.net/opds-pse/stream') ||
          rel.contains('opds-pse/stream') ||
          rel.contains('pse/stream')) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  OpdsEntryKind _detectKind(List<XmlElement> links) {
    for (final link in links) {
      final rel = (link.getAttribute('rel') ?? '').toLowerCase();
      if (rel.contains('acquisition') || rel.contains('/open-access')) {
        return OpdsEntryKind.publication;
      }

      final type = (link.getAttribute('type') ?? '').toLowerCase();
      if (type.contains('comicbook') ||
          type.contains('epub') ||
          type.contains('pdf') ||
          type.contains('zip')) {
        return OpdsEntryKind.publication;
      }

      final href = (link.getAttribute('href') ?? '').toLowerCase();
      if (href.endsWith('.cbz') ||
          href.endsWith('.cbr') ||
          href.endsWith('.epub') ||
          href.endsWith('.pdf') ||
          href.endsWith('.zip')) {
        return OpdsEntryKind.publication;
      }
    }
    return OpdsEntryKind.navigation;
  }
}