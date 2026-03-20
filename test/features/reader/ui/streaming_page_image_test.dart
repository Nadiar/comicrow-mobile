import 'dart:async';
import 'dart:typed_data';

import 'package:comicrow/features/reader/widgets/streaming_page_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {

  Widget buildSubject({
    required Future<Uint8List?> Function() pageLoader,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: StreamingPageImage(
            pageUrl: 'https://example.com/page.jpg',
            pageLoader: pageLoader,
          ),
        ),
      ),
    );
  }

  testWidgets('shows spinner when load exceeds delay', (tester) async {
    final completer = Completer<Uint8List?>();

    await tester.pumpWidget(
      buildSubject(
        pageLoader: () async {
          return completer.future;
        },
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 650));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(pngBytes);
    await tester.pump();
  });

  testWidgets('hides spinner after image load completes', (tester) async {
    var scheduled = false;

    await tester.pumpWidget(
      buildSubject(
        pageLoader: () async {
          if (!scheduled) {
            scheduled = true;
            await Future<void>.delayed(const Duration(milliseconds: 700));
          }
          return pngBytes;
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows retry UI on error and can retry', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      buildSubject(
        pageLoader: () async {
          attempts += 1;
          if (attempts == 1) {
            throw Exception('fail');
          }
          return pngBytes;
        },
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to load page'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to load page'), findsNothing);
  });
}
