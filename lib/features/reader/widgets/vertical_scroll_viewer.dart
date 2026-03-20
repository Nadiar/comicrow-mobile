import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../providers/reader_provider.dart';
import 'streaming_page_image.dart';

/// Vertical scroll viewer for webtoon-style reading (continuous vertical scroll)
class VerticalScrollViewer extends StatefulWidget {
  const VerticalScrollViewer({
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
  State<VerticalScrollViewer> createState() => _VerticalScrollViewerState();
}

class _VerticalScrollViewerState extends State<VerticalScrollViewer> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialPage());
  }

  @override
  void didUpdateWidget(covariant VerticalScrollViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToInitialPage());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Calculate current page based on scroll position
    final offset = _scrollController.offset;
    final viewportHeight = MediaQuery.of(context).size.height;
    final currentPage = (offset / viewportHeight).toInt().clamp(0, widget.pageCount - 1);
    widget.onPageChanged(currentPage);
  }

  void _jumpToInitialPage() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    final viewportHeight = MediaQuery.of(context).size.height;
    final offset = widget.initialPage * viewportHeight;
    _scrollController.jumpTo(offset);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.pageCount,
      itemBuilder: (context, index) {
        if (widget.isStreaming) {
          return AspectRatio(
            aspectRatio: 0.72,
            child: StreamingPageImage(
              pageUrl: widget.streamingPageUrls[index].toString(),
              thumbnailUrl: widget.thumbnailUrl,
              headers: widget.authorizationHeader == null
                  ? null
                  : <String, String>{'Authorization': widget.authorizationHeader!},
              fit: BoxFit.contain,
            ),
          );
        }

        return Image.memory(
          widget.pages[index],
          fit: BoxFit.fitWidth,
          width: double.infinity,
        );
      },
    );
  }
}
