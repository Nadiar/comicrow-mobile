import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/app_preferences_provider.dart';
import '../providers/reader_provider.dart';
import '../widgets/double_page_viewer.dart';
import '../widgets/single_page_viewer.dart';
import '../widgets/streaming_page_image.dart';
import '../widgets/vertical_scroll_viewer.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    this.publicationUrl,
    this.title,
    this.pseStreamUrl,
    this.divinaManifestUrl,
    this.thumbnailUrl,
    super.key,
  });

  final String? publicationUrl;
  final String? title;
  final String? pseStreamUrl;
  final String? divinaManifestUrl;
  final String? thumbnailUrl;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showOverlay = true;
  bool _hasManualModeOverride = false;

  void _setReadingMode(ReaderController controller, ReaderMode mode) {
    setState(() {
      _hasManualModeOverride = true;
    });
    controller.setReadingMode(mode);
  }

  void _syncOrientationMode({
    required ReaderState readerState,
    required ReaderController controller,
    required Orientation orientation,
    required bool autoDoublePage,
  }) {
    if (!autoDoublePage || _hasManualModeOverride) {
      return;
    }

    final targetMode = orientation == Orientation.landscape
        ? ReaderMode.double
        : ReaderMode.single;
    if (readerState.readingMode == targetMode) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      controller.setReadingMode(targetMode);
    });
  }

  Widget _buildViewer(ReaderState readerState, ReaderController controller) {
    switch (readerState.readingMode) {
      case ReaderMode.double:
        return DoublePageViewer(
          pages: readerState.pages,
          streamingPageUrls: readerState.streamingPageUrls,
          initialPage: readerState.currentPage,
          direction: readerState.direction,
          thumbnailUrl: readerState.thumbnailUrl,
          authorizationHeader: readerState.authorizationHeader,
          onPageChanged: controller.setPage,
        );
      case ReaderMode.vertical:
        return VerticalScrollViewer(
          pages: readerState.pages,
          streamingPageUrls: readerState.streamingPageUrls,
          initialPage: readerState.currentPage,
          direction: readerState.direction,
          thumbnailUrl: readerState.thumbnailUrl,
          authorizationHeader: readerState.authorizationHeader,
          onPageChanged: controller.setPage,
        );
      case ReaderMode.single:
        return SinglePageViewer(
          pages: readerState.pages,
          streamingPageUrls: readerState.streamingPageUrls,
          initialPage: readerState.currentPage,
          direction: readerState.direction,
          thumbnailUrl: readerState.thumbnailUrl,
          authorizationHeader: readerState.authorizationHeader,
          onPageChanged: controller.setPage,
        );
    }
  }

  String _modeLabel(ReaderMode mode) {
    switch (mode) {
      case ReaderMode.single:
        return 'Single page';
      case ReaderMode.double:
        return 'Double-page spread';
      case ReaderMode.vertical:
        return 'Vertical scroll';
    }
  }

  IconData _modeIcon(ReaderMode mode) {
    switch (mode) {
      case ReaderMode.single:
        return Icons.chrome_reader_mode_outlined;
      case ReaderMode.double:
        return Icons.auto_stories_outlined;
      case ReaderMode.vertical:
        return Icons.view_stream_outlined;
    }
  }

  Color _modeColor(ReaderMode mode) {
    switch (mode) {
      case ReaderMode.single:
        return Colors.blueGrey.shade200;
      case ReaderMode.double:
        return Colors.amber.shade200;
      case ReaderMode.vertical:
        return Colors.tealAccent.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.publicationUrl;
    if (url == null || url.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: const Center(child: Text('No publication selected.')),
      );
    }

    final request = ReaderRequest(
      publicationUrl: url,
      pseStreamUrl: widget.pseStreamUrl,
      divinaManifestUrl: widget.divinaManifestUrl,
      thumbnailUrl: widget.thumbnailUrl,
    );

    final state = ref.watch(readerControllerProvider(request));
    final controller = ref.read(readerControllerProvider(request).notifier);
    final globalAutoDoublePage = ref.watch(autoDoublePageProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: state.when(
        loading: () => Stack(
          fit: StackFit.expand,
          children: [
            if (((widget.pseStreamUrl ?? '').isNotEmpty ||
                    (widget.divinaManifestUrl ?? '').isNotEmpty) &&
                (widget.thumbnailUrl ?? '').isNotEmpty)
              StreamingPageImage(
                pageUrl: widget.thumbnailUrl!,
                thumbnailUrl: widget.thumbnailUrl,
                fit: BoxFit.contain,
              )
            else
              const ColoredBox(color: Colors.black),
            Container(color: Colors.black.withValues(alpha: 0.4)),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading comic...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(readerControllerProvider(request));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (readerState) {
          return OrientationBuilder(
            builder: (context, orientation) {
              _syncOrientationMode(
                readerState: readerState,
                controller: controller,
                orientation: orientation,
                autoDoublePage: readerState.autoDoublePage || globalAutoDoublePage,
              );

              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _showOverlay = !_showOverlay),
                    child: _buildViewer(readerState, controller),
                  ),
                  AnimatedOpacity(
                    opacity: _showOverlay ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: Column(
                        children: [
                          SafeArea(
                            bottom: false,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(context).maybePop(),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.title ?? 'Reader',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _modeColor(readerState.readingMode),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _modeIcon(readerState.readingMode),
                                          color: _modeColor(readerState.readingMode),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _modeLabel(readerState.readingMode),
                                          style: TextStyle(
                                            color: _modeColor(readerState.readingMode),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<ReaderMode>(
                                    tooltip: 'Reading mode',
                                    initialValue: readerState.readingMode,
                                    icon: Icon(
                                      _modeIcon(readerState.readingMode),
                                      color: Colors.white,
                                    ),
                                    color: Colors.grey.shade900,
                                    onSelected: (mode) => _setReadingMode(controller, mode),
                                    itemBuilder: (context) => ReaderMode.values
                                        .map(
                                          (mode) => PopupMenuItem<ReaderMode>(
                                            value: mode,
                                            child: Text(
                                              _modeLabel(mode),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${readerState.currentPage + 1} / ${readerState.pageCount}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          SafeArea(
                            top: false,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: controller.toggleDirection,
                                    icon: Icon(
                                      readerState.direction == ReaderDirection.ltr
                                          ? Icons.format_textdirection_l_to_r
                                          : Icons.format_textdirection_r_to_l,
                                      color: Colors.white,
                                    ),
                                    tooltip: readerState.direction == ReaderDirection.ltr
                                        ? 'Switch to RTL'
                                        : 'Switch to LTR',
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: readerState.currentPage.toDouble(),
                                      min: 0,
                                      max: (readerState.pageCount - 1).toDouble(),
                                      divisions: readerState.pageCount > 1
                                          ? readerState.pageCount - 1
                                          : null,
                                      label: '${readerState.currentPage + 1}',
                                      onChanged: readerState.pageCount > 1
                                          ? (value) {
                                              controller.setPage(value.round());
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
