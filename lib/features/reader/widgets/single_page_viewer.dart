import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../providers/reader_provider.dart';
import 'streaming_page_image.dart';

/// Single-page viewer with swipe-based page turning
class SinglePageViewer extends StatefulWidget {
  const SinglePageViewer({
    required this.pages,
    required this.initialPage,
    required this.direction,
    required this.onPageChanged,
    this.streamingPageUrls = const <Uri>[],
    this.thumbnailUrl,
    this.authorizationHeader,
    super.key,
  });

  final List<Uint8List> pages;
  final List<Uri> streamingPageUrls;
  final int initialPage;
  final ReaderDirection direction;
  final ValueChanged<int> onPageChanged;
  final String? thumbnailUrl;
  final String? authorizationHeader;

  bool get isStreaming => streamingPageUrls.isNotEmpty;

  int get pageCount => isStreaming ? streamingPageUrls.length : pages.length;

  @override
  State<SinglePageViewer> createState() => _SinglePageViewerState();
}

class _SinglePageViewerState extends State<SinglePageViewer> {
  late PageController _pageController;

  int get _displayPage => widget.direction == ReaderDirection.ltr
      ? widget.initialPage
      : widget.pageCount - 1 - widget.initialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _displayPage);
  }

  @override
  void didUpdateWidget(covariant SinglePageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage ||
        oldWidget.direction != widget.direction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(_displayPage);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      onPageChanged: (displayIndex) {
        final logicalIndex = widget.direction == ReaderDirection.ltr
            ? displayIndex
            : widget.pageCount - 1 - displayIndex;
        widget.onPageChanged(logicalIndex);
      },
      itemCount: widget.pageCount,
      builder: (context, index) {
        final pageIndex = widget.direction == ReaderDirection.ltr
            ? index
            : widget.pageCount - 1 - index;
        if (widget.isStreaming) {
          return PhotoViewGalleryPageOptions.customChild(
            child: StreamingPageImage(
              pageUrl: widget.streamingPageUrls[pageIndex].toString(),
              thumbnailUrl: widget.thumbnailUrl,
              headers: widget.authorizationHeader == null
                  ? null
                  : <String, String>{'Authorization': widget.authorizationHeader!},
              fit: BoxFit.contain,
            ),
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          );
        }

        return PhotoViewGalleryPageOptions(
          imageProvider: MemoryImage(widget.pages[pageIndex]),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2.0,
        );
      },
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }
}
