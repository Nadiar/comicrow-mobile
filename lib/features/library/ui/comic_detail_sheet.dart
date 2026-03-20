import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/opds/models.dart';
import '../../downloads/providers/downloads_provider.dart';
import '../models/comic_metadata.dart';

class ComicDetailSheet extends ConsumerWidget {
  const ComicDetailSheet({
    required this.entry,
    required this.baseUri,
    this.metadata,
    this.onRead,
    super.key,
  });

  final OpdsEntry entry;
  final Uri baseUri;
  final ComicMetadata? metadata;
  final ValueChanged<BuildContext>? onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = metadata ?? ComicMetadata.empty();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Thumbnail + Publication Info
              if (entry.thumbnailHref != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          baseUri.resolve(entry.thumbnailHref!).toString(),
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (meta.series != null) ...[
                              Text(
                                meta.series!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (meta.number != null) ...[
                              Text(
                                'Issue #${meta.number}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (meta.year != null) ...[
                              Text(
                                'Published: ${meta.year}${meta.month != null ? '/${meta.month}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (meta.publisher != null) ...[
                              Text(
                                'Publisher: ${meta.publisher}',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary
              if (entry.summary?.isNotEmpty == true) ...[
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ] else if (meta.summary?.isNotEmpty == true) ...[
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  meta.summary!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Credits
              if (meta.creditsString.isNotEmpty) ...[
                Text(
                  'Credits',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  meta.creditsString,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],

              // Genre
              if (meta.genre?.isNotEmpty == true) ...[
                Wrap(
                  spacing: 8,
                  children: meta.genre!.split(',').map((genre) {
                    return Chip(
                      label: Text(genre.trim()),
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close detail sheet
                          onRead?.call(context);
                        },
                        child: const Text('Read'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          // Trigger download
                          final controller = ref.read(downloadControllerProvider);
                          final publicationUri = baseUri.resolve(entry.href);
                          controller.enqueueDownload(
                            publicationUri: publicationUri,
                            title: entry.title,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${entry.title} added to downloads'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Download'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
