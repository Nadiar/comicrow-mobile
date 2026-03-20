import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/image_cache.dart';
import '../../reader/providers/reader_provider.dart';
import '../../reader/services/page_cache_manager.dart';
import '../../servers/data/server_repository.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/reading_preset_provider.dart';

String _serverReadingModeLabel(ReaderMode mode) {
  switch (mode) {
    case ReaderMode.single:
      return 'Single page';
    case ReaderMode.double:
      return 'Double-page spread';
    case ReaderMode.vertical:
      return 'Vertical scroll';
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    this.onOpenLibraries,
    super.key,
  });

  final VoidCallback? onOpenLibraries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final prefController = ref.read(appPreferencesProvider.notifier);
    final presetController = ref.read(readingPresetControllerProvider);
    final servers = ref.watch(savedServersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onOpenLibraries == null
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Libraries',
                onPressed: onOpenLibraries,
              ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text('Servers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: servers.when(
                data: (serverList) {
                  if (serverList.isEmpty) {
                    return const ListTile(
                      leading: Icon(Icons.cloud_off_outlined),
                      title: Text('No servers configured'),
                    );
                  }

                  return Column(
                    children: [
                      for (final server in serverList)
                        Builder(builder: (context) {
                          final preset = ref.watch(serverReadingPresetProvider(server));
                          return ListTile(
                            leading: const Icon(Icons.cloud_outlined),
                            title: Text(server.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(server.url),
                                const SizedBox(height: 8),
                                const Text('Default reading mode'),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<ReaderMode>(
                                    value: preset.defaultReadingMode,
                                    items: ReaderMode.values
                                        .map(
                                          (mode) => DropdownMenuItem<ReaderMode>(
                                            value: mode,
                                            child: Text(_serverReadingModeLabel(mode)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (mode) async {
                                      if (mode == null) {
                                        return;
                                      }
                                      await presetController.savePreset(
                                        serverId: server.id,
                                        defaultReadingMode: mode,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Auto double-page in landscape'),
                                  value: preset.autoDoublePage,
                                  onChanged: (value) async {
                                    await presetController.savePreset(
                                      serverId: server.id,
                                      autoDoublePage: value,
                                    );
                                  },
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit server',
                                  onPressed: () {
                                    context.go('/servers/edit/${server.id}');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete server',
                                  onPressed: () async {
                                    await ref
                                        .read(serverRepositoryProvider)
                                        .deleteServer(server.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Removed ${server.name}.'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error.toString()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.go('/servers/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add OPDS Server'),
            ),
            const SizedBox(height: 20),
            Text('Reading', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Global auto double-page in landscape'),
                      subtitle: const Text(
                        'Applied in addition to per-library reading presets.',
                      ),
                      value: preferences.autoDoublePage,
                      onChanged: prefController.setAutoDoublePage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {preferences.themeMode},
                  onSelectionChanged: (selection) {
                    final choice = selection.first;
                    prefController.setThemeMode(choice);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Cache', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max cache size: ${preferences.cacheSizeMb} MB'),
                    Slider(
                      value: preferences.cacheSizeMb.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '${preferences.cacheSizeMb} MB',
                      onChanged: (value) {
                        final mb = value.round();
                        prefController.setCacheSizeMb(mb);
                        ref.read(pageCacheManagerProvider).maxBytes = mb * 1024 * 1024;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          imageCache.clear();
                          imageCache.clearLiveImages();
                          ref.read(pageCacheManagerProvider).clear();
                          ref.read(imageCacheStoreProvider).clearMemory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All caches cleared.')),
                          );
                        },
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Clear Image Cache'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}