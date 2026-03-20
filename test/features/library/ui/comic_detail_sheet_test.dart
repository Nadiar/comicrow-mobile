import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:comicrow/core/opds/models.dart';
import 'package:comicrow/features/library/models/comic_metadata.dart';
import 'package:comicrow/features/library/ui/comic_detail_sheet.dart';

void main() {
  group('ComicDetailSheet', () {
    late OpdsEntry mockEntry;
    late Uri mockBaseUri;
    late ComicMetadata mockMetadata;

    setUp(() {
      mockBaseUri = Uri.parse('https://example.com/opds/');
      mockEntry = const OpdsEntry(
        title: 'Test Comic',
        href: '/publications/test-comic',
        kind: OpdsEntryKind.publication,
        summary: 'A great comic story',
        thumbnailHref: '/images/test-comic.jpg',
      );
      mockMetadata = ComicMetadata.fromXmlString('''<?xml version="1.0"?>
<ComicInfo>
  <Title>Test Comic</Title>
  <Series>Test Series</Series>
  <Number>1</Number>
  <Publisher>Test Publisher</Publisher>
  <Year>2024</Year>
</ComicInfo>''');
    });

    testWidgets('displays entry title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Comic'), findsWidgets);
    });

    testWidgets('displays summary when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('A great comic story'), findsOneWidget);
    });

    testWidgets('displays metadata from ComicInfo', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Series'), findsOneWidget);
      expect(find.text('Issue #1'), findsOneWidget);
      expect(find.text('Publisher: Test Publisher'), findsOneWidget);
    });

    testWidgets('has Read button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('has Download button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('calls onRead callback when Read is tapped', (WidgetTester tester) async {
      var readCalled = false;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: mockMetadata,
                onRead: (_) {
                  readCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();

      expect(readCalled, true);
    });

    testWidgets('handles empty metadata gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComicDetailSheet(
                entry: mockEntry,
                baseUri: mockBaseUri,
                metadata: ComicMetadata.empty(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Comic'), findsWidgets);
      // Should still show summary from OpdsEntry
      expect(find.text('A great comic story'), findsOneWidget);
    });
  });
}
