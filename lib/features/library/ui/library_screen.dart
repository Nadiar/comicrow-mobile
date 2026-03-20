import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/opds/models.dart';
import '../../../core/storage/image_cache.dart';
import '../../downloads/providers/downloads_provider.dart';
import '../models/comic_metadata.dart';
import '../providers/library_catalog_provider.dart';
import '../ui/comic_detail_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({
    this.onOpenLibraries,
    this.onOpenSettings,
    super.key,
  });

  final VoidCallback? onOpenLibraries;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref.read(libraryBrowseControllerProvider.notifier).search(value);
    });
  }

  Future<void> _onRefresh() {
    return ref.read(libraryBrowseControllerProvider.notifier).refresh();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        ref.read(libraryBrowseControllerProvider.notifier).clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryBrowseControllerProvider);
    final controller = ref.read(libraryBrowseControllerProvider.notifier);

    return Scaffold(
      body: state.when(
        data: (browseState) {
          final catalog = browseState.feed;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(catalog.title),
                  leading: widget.onOpenLibraries == null
                      ? (browseState.canGoBack
                            ? IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: controller.goBack,
                              )
                            : null)
                      : IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Libraries',
                          onPressed: widget.onOpenLibraries,
                        ),
                  actions: [
                    if (browseState.canGoBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: controller.goBack,
                      ),
                    if (catalog.searchUrl != null)
                      IconButton(
                        onPressed: _toggleSearch,
                        icon: Icon(
                          _isSearchVisible ? Icons.close : Icons.search,
                        ),
                      ),
                    if (widget.onOpenSettings != null)
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                        onPressed: widget.onOpenSettings,
                      ),
                  ],
                  bottom: _isSearchVisible
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(56),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Search catalog',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Text(
                      'Source: ${browseState.serverName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                if (catalog.entries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Catalog is empty.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final crossAxisCount = width >= 1100
                            ? 6
                            : width >= 800
                            ? 5
                            : width >= 600
                            ? 4
                            : 3;

                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final entry = catalog.entries[index];
                            return _GridEntryTile(
                              entry: entry,
                              thumbnailHeaders: browseState.thumbnailHeaders,
                              imageUrl: entry.thumbnailHref == null
                                  ? null
                                  : browseState.currentUri
                                        .resolve(entry.thumbnailHref!)
                                        .toString(),
                              onDownload: entry.kind == OpdsEntryKind.publication
                                  ? () async {
                                      final publicationUri = controller
                                          .resolvePublicationUri(entry);
                                      final thumbnail = entry.thumbnailHref == null
                                          ? null
                                          : browseState.currentUri
                                                .resolve(entry.thumbnailHref!)
                                                .toString();
                                      try {
                                        await ref
                                            .read(downloadControllerProvider)
                                            .enqueueDownload(
                                              publicationUri: publicationUri,
                                              title: entry.title,
                                              thumbnailUrl: thumbnail,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Downloaded ${entry.title}.',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Download failed: $error',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              onTap: () async {
                                if (entry.kind == OpdsEntryKind.navigation) {
                                  await controller.openEntry(entry);
                                  return;
                                }

                                // Show detail sheet for publications
                                if (context.mounted) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (sheetContext) {
                                      return ComicDetailSheet(
                                        entry: entry,
                                        baseUri: browseState.currentUri,
                                        metadata: ComicMetadata.empty(),
                                        onRead: (sheetCtx) {
                                          // Handle read action
                                          final publicationUri = controller
                                              .resolvePublicationUri(entry);
                                          final pseUri = entry.pseStreamHref == null
                                              ? null
                                              : browseState.currentUri
                                                    .resolve(entry.pseStreamHref!)
                                                    .toString();
                                          final divinaUri = entry.divinaManifestHref == null
                                              ? null
                                              : browseState.currentUri
                                                    .resolve(entry.divinaManifestHref!)
                                                    .toString();
                                          final thumbnailUri = entry.thumbnailHref == null
                                              ? null
                                              : browseState.currentUri
                                                    .resolve(entry.thumbnailHref!)
                                                    .toString();
                                          if (context.mounted) {
                                            final query = <String, String>{
                                              'url': publicationUri.toString(),
                                              'title': entry.title,
                                            };
                                            if (pseUri != null && pseUri.isNotEmpty) {
                                              query['pse'] = pseUri;
                                            }
                                            if (divinaUri != null && divinaUri.isNotEmpty) {
                                              query['divina'] = divinaUri;
                                            }
                                            if (thumbnailUri != null &&
                                                thumbnailUri.isNotEmpty) {
                                              query['thumb'] = thumbnailUri;
                                            }
                                            context.push(
                                              Uri(
                                                path: '/reader',
                                                queryParameters: query,
                                              ).toString(),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            );
                          }, childCount: catalog.entries.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                              ),
                        );
                      },
                    ),
                  ),
                if (catalog.nextHref != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: FilledButton.icon(
                        onPressed: browseState.isLoadingNextPage
                            ? null
                            : controller.loadNextPage,
                        icon: browseState.isLoadingNextPage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          browseState.isLoadingNextPage
                              ? 'Loading...'
                              : 'Load Next Page',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridEntryTile extends StatelessWidget {
  const _GridEntryTile({
    required this.entry,
    required this.imageUrl,
    required this.thumbnailHeaders,
    required this.onTap,
    this.onDownload,
  });

  final OpdsEntry entry;
  final String? imageUrl;
  final Map<String, String>? thumbnailHeaders;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _CoverImage(
                imageUrl: imageUrl,
                kind: entry.kind,
                headers: thumbnailHeaders,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.kind == OpdsEntryKind.navigation
                      ? 'Folder'
                      : 'Publication',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (entry.kind == OpdsEntryKind.publication)
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Download',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends ConsumerStatefulWidget {
  const _CoverImage({
    required this.imageUrl,
    required this.kind,
    this.headers,
  });

  final String? imageUrl;
  final OpdsEntryKind kind;
  final Map<String, String>? headers;

  @override
  ConsumerState<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends ConsumerState<_CoverImage> {
  Future<Uint8List?>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        !mapEquals(oldWidget.headers, widget.headers)) {
      _thumbnailFuture = _loadThumbnail();
    }
  }

  Future<Uint8List?> _loadThumbnail() {
    final imageUrl = widget.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Future<Uint8List?>.value(null);
    }

    return ref.read(imageCacheStoreProvider).getThumbnailBytes(
          imageUrl,
          headers: widget.headers,
        );
  }

  Widget _fallbackCover(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          widget.kind == OpdsEntryKind.navigation
              ? Icons.folder_open_outlined
              : Icons.menu_book_outlined,
          size: 34,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _fallbackCover(context);
    }

    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _fallbackCover(context);
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}