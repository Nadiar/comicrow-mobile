import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/servers/data/server_repository.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) : _ref = ref {
    ref.listen<AsyncValue<int>>(serverCountProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final countAsync = _ref.read(serverCountProvider);
    return countAsync.when(
      data: (count) {
        if (count == 0 && state.matchedLocation != '/servers/add') {
          return '/servers/add';
        }
        return null;
      },
      loading: () => null,
      error: (_, _) => null,
    );
  }
}
