import 'package:comicrow/app.dart';
import 'package:comicrow/features/servers/data/server_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('redirects to add server when no servers are configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverCountProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: const ComicRowApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Server'), findsOneWidget);
    expect(find.text('Test Connection'), findsOneWidget);
    expect(find.text('Server name'), findsOneWidget);
  });
}
