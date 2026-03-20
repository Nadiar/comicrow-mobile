import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/downloads/ui/downloads_screen.dart';
import '../../features/library/ui/library_screen.dart';
import '../../features/reader/ui/reader_screen.dart';
import '../../features/settings/providers/app_preferences_provider.dart';
import '../../features/servers/data/server_repository.dart';
import '../../features/servers/ui/add_server_screen.dart';
import '../../features/servers/ui/edit_server_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import 'router_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final router = GoRouter(
    initialLocation: '/library',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/library',
        builder: (context, state) => const HomeShell(currentIndex: 0),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const HomeShell(currentIndex: 1),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const HomeShell(currentIndex: 2),
      ),
      GoRoute(
        path: '/servers/add',
        builder: (context, state) => const AddServerScreen(),
      ),
      GoRoute(
        path: '/servers/edit/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid server id.')),
            );
          }
          return EditServerScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'];
          final title = state.uri.queryParameters['title'];
          final pse = state.uri.queryParameters['pse'];
          final divina = state.uri.queryParameters['divina'];
          final thumb = state.uri.queryParameters['thumb'];
          return ReaderScreen(
            publicationUrl: url,
            title: title,
            pseStreamUrl: pse,
            divinaManifestUrl: divina,
            thumbnailUrl: thumb,
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    Widget buildCurrentScreen() {
      switch (widget.currentIndex) {
        case 1:
          return DownloadsScreen(
            onOpenLibraries: () => _scaffoldKey.currentState?.openDrawer(),
            onOpenSettings: () => context.go('/settings'),
          );
        case 2:
          return SettingsScreen(
            onOpenLibraries: () => _scaffoldKey.currentState?.openDrawer(),
          );
        case 0:
        default:
          return LibraryScreen(
            onOpenLibraries: () => _scaffoldKey.currentState?.openDrawer(),
            onOpenSettings: () => context.go('/settings'),
          );
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _LibrariesDrawer(),
      body: buildCurrentScreen(),
    );
  }
}

class _LibrariesDrawer extends ConsumerWidget {
  const _LibrariesDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(savedServersProvider);
    final activeServerId = ref.watch(activeLibraryServerIdProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Libraries',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Downloads'),
              selected: currentLocation == '/downloads',
              onTap: () {
                Navigator.of(context).pop();
                context.go('/downloads');
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: servers.when(
                data: (serverList) {
                  if (serverList.isEmpty) {
                    return const Center(child: Text('No libraries configured'));
                  }

                  final selectedServerId = activeServerId ?? serverList.first.id;

                  return ListView(
                    children: [
                      for (final server in serverList)
                        ListTile(
                          leading: const Icon(Icons.collections_bookmark_outlined),
                          title: Text(server.name),
                          subtitle: Text(
                            server.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: currentLocation == '/library' &&
                              selectedServerId == server.id,
                          onTap: () async {
                            await ref
                                .read(appPreferencesProvider.notifier)
                                .setActiveServerId(server.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              context.go('/library');
                            }
                          },
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(error.toString()),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/servers/add');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Library'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}