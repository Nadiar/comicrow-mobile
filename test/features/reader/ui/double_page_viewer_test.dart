import 'dart:typed_data';

import 'package:comicrow/features/reader/providers/reader_provider.dart';
import 'package:comicrow/features/reader/widgets/double_page_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  List<Uint8List> buildPages(int count) {
    return List<Uint8List>.generate(count, (_) => pngBytes);
  }

  testWidgets('tap zones respect RTL navigation in double-page mode', (
    tester,
  ) async {
    var currentPage = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: DoublePageViewer(
              pages: buildPages(4),
              initialPage: 0,
              direction: ReaderDirection.rtl,
              onPageChanged: (page) {
                currentPage = page;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('double-page-left-zone')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(currentPage, 2);
  });
}