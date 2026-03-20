import 'package:xml/xml.dart' as xml;

class ComicMetadata {
  const ComicMetadata({
    this.title,
    this.series,
    this.number,
    this.count,
    this.volume,
    this.year,
    this.month,
    this.writer,
    this.penciller,
    this.inker,
    this.colorist,
    this.letterer,
    this.coverArtist,
    this.publisher,
    this.imprint,
    this.genre,
    this.summary,
    this.notes,
    this.mangaStyle = false,
  });

  final String? title;
  final String? series;
  final String? number;
  final int? count;
  final int? volume;
  final int? year;
  final int? month;
  final String? writer;
  final String? penciller;
  final String? inker;
  final String? colorist;
  final String? letterer;
  final String? coverArtist;
  final String? publisher;
  final String? imprint;
  final String? genre;
  final String? summary;
  final String? notes;
  final bool mangaStyle;

  factory ComicMetadata.fromXmlString(String xmlString) {
    try {
      final doc = xml.XmlDocument.parse(xmlString);
      final root = doc.rootElement;

      return ComicMetadata(
        title: _getElementText(root, 'Title'),
        series: _getElementText(root, 'Series'),
        number: _getElementText(root, 'Number'),
        count: _parseIntElement(root, 'Count'),
        volume: _parseIntElement(root, 'Volume'),
        year: _parseIntElement(root, 'Year'),
        month: _parseIntElement(root, 'Month'),
        writer: _getElementText(root, 'Writer'),
        penciller: _getElementText(root, 'Penciller'),
        inker: _getElementText(root, 'Inker'),
        colorist: _getElementText(root, 'Colorist'),
        letterer: _getElementText(root, 'Letterer'),
        coverArtist: _getElementText(root, 'CoverArtist'),
        publisher: _getElementText(root, 'Publisher'),
        imprint: _getElementText(root, 'Imprint'),
        genre: _getElementText(root, 'Genre'),
        summary: _getElementText(root, 'Summary'),
        notes: _getElementText(root, 'Notes'),
        mangaStyle: (_getElementText(root, 'Manga') ?? '').toLowerCase() == 'yes',
      );
    } catch (e) {
      return const ComicMetadata();
    }
  }

  factory ComicMetadata.empty() => const ComicMetadata();

  bool get isEmpty =>
      title == null &&
      series == null &&
      summary == null &&
      writer == null &&
      penciller == null &&
      publisher == null &&
      genre == null &&
      year == null;

  String get creditsString {
    final credits = <String>[];
    if (writer != null) credits.add('Writer: $writer');
    if (penciller != null) credits.add('Penciller: $penciller');
    if (inker != null) credits.add('Inker: $inker');
    if (colorist != null) credits.add('Colorist: $colorist');
    if (letterer != null) credits.add('Letterer: $letterer');
    if (coverArtist != null) credits.add('Cover: $coverArtist');
    return credits.join('\n');
  }

  String get publicationInfo {
    final info = <String>[];
    if (series != null || number != null) {
      final seriesStr = series ?? 'Unknown Series';
      final numberStr = number ?? '0';
      info.add('$seriesStr #$numberStr');
    }
    if (volume != null) info.add('Vol. $volume');
    if (year != null || month != null) {
      final yearStr = year?.toString() ?? '???';
      final monthStr = month != null ? '$month/' : '';
      info.add('$monthStr$yearStr');
    }
    if (publisher != null) info.add('Publisher: $publisher');
    return info.join(' • ');
  }

  static String? _getElementText(xml.XmlElement root, String tagName) {
    try {
      final element = root.findElements(tagName).firstOrNull;
      final text = element?.innerText;
      return text?.isNotEmpty == true ? text : null;
    } catch (e) {
      return null;
    }
  }

  static int? _parseIntElement(xml.XmlElement root, String tagName) {
    final text = _getElementText(root, tagName);
    if (text == null) return null;
    return int.tryParse(text);
  }
}
