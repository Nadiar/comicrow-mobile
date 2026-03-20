import 'package:flutter_test/flutter_test.dart';

import 'package:comicrow/features/library/models/comic_metadata.dart';

void main() {
  group('ComicMetadata', () {
    test('parses basic ComicInfo.xml', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Sample Comic</Title>
  <Series>Great Series</Series>
  <Number>42</Number>
  <Count>50</Count>
  <Year>2024</Year>
</ComicInfo>''';

      final metadata = ComicMetadata.fromXmlString(xml);
      
      expect(metadata.title, 'Sample Comic');
      expect(metadata.series, 'Great Series');
      expect(metadata.number, '42');
      expect(metadata.count, 50);
      expect(metadata.year, 2024);
    });

    test('handles missing optional fields', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Minimal Comic</Title>
</ComicInfo>''';

      final metadata = ComicMetadata.fromXmlString(xml);
      
      expect(metadata.title, 'Minimal Comic');
      expect(metadata.series, isNull);
      expect(metadata.year, isNull);
    });

    test('parses credits fields', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Story Time</Title>
  <Writer>Author Name</Writer>
  <Penciller>Artist Name</Penciller>
  <Publisher>Publisher Inc</Publisher>
</ComicInfo>''';

      final metadata = ComicMetadata.fromXmlString(xml);
      
      expect(metadata.writer, 'Author Name');
      expect(metadata.penciller, 'Artist Name');
      expect(metadata.publisher, 'Publisher Inc');
      expect(metadata.creditsString, contains('Writer: Author Name'));
      expect(metadata.creditsString, contains('Penciller: Artist Name'));
    });

    test('detects manga style', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Manga</Title>
  <Manga>Yes</Manga>
</ComicInfo>''';

      final metadata = ComicMetadata.fromXmlString(xml);
      expect(metadata.mangaStyle, true);
    });

    test('handles malformed XML gracefully', () {
      const invalidXml = 'not xml at all';
      final metadata = ComicMetadata.fromXmlString(invalidXml);
      
      expect(metadata.isEmpty, true);
    });

    test('builds publication info string', () {
      const xml = '''<?xml version="1.0" encoding="utf-8"?>
<ComicInfo>
  <Title>Test</Title>
  <Series>Test Series</Series>
  <Number>10</Number>
  <Year>2023</Year>
  <Publisher>Big Publisher</Publisher>
</ComicInfo>''';

      final metadata = ComicMetadata.fromXmlString(xml);
      final info = metadata.publicationInfo;
      
      expect(info, contains('Test Series #10'));
      expect(info, contains('2023'));
      expect(info, contains('Publisher: Big Publisher'));
    });
  });
}
