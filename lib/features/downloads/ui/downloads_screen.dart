import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/download_repository.dart';
import '../providers/downloads_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({
    this.onOpenLibraries,
    this.onOpenSettings,
    super.key,
  });

  final VoidCallback? onOpenLibraries;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeDownloadsProvider);
    final completed = ref.watch(completedDownloadsProvider);
    final controller = ref.read(downloadControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onOpenLibraries == null
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Libraries',
                onPressed: onOpenLibraries,
              ),
        title: const Text('Downloads'),
        actions: [
          if (onOpenSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: onOpenSettings,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Text('Downloading', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: active.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const ListTile(
                      leading: Icon(Icons.download_outlined),
                      title: Text('No active downloads'),
                    );
                  }

                  return Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          leading: const CircularProgressIndicator(strokeWidth: 2),
                          title: Text(item.title),
                          subtitle: Text(item.status),
                        ),
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
            const SizedBox(height: 18),
            Text('Downloaded', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: completed.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const ListTile(
                      leading: Icon(Icons.cloud_download_outlined),
                      title: Text('No completed downloads yet'),
                    );
                  }

                  return Column(
                    children: [
                      for (final item in items)
                        ListTile(
                          onTap: () {
                            context.push(
                              '/reader?url=${Uri.encodeComponent(item.publicationUrl)}&title=${Uri.encodeComponent(item.title)}',
                            );
                          },
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(item.title),
                          subtitle: Text(
                            '${(item.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await controller.deleteDownload(item.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed ${item.title} download.'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }
}