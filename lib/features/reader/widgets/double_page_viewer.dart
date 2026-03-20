import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../providers/reader_provider.dart';
import 'streaming_page_image.dart';

/// Double-page spread viewer for landscape orientation
class DoublePageViewer extends StatefulWidget {
  const DoublePageViewer({
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
  State<DoublePageViewer> createState() => _DoublePageViewerState();
}

class _DoublePageViewerState extends State<DoublePageViewer> {
  late PageController _pageController;

  int get _initialSpread => widget.initialPage ~/ 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialSpread,
      viewportFraction: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant DoublePageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(_initialSpread);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextSpread() {
    if (_pageController.page != null) {
      final nextPage = (_pageController.page!.toInt() + 1).clamp(
        0,
        (widget.pageCount / 2).ceil() - 1,
      );
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousSpread() {
    if (_pageController.page != null) {
      final prevPage = (_pageController.page!.toInt() - 1).clamp(
        0,
        (widget.pageCount / 2).ceil() - 1,
      );
      _pageController.animateToPage(
        prevPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPage(int index) {
    if (widget.isStreaming) {
      return PhotoView.customChild(
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        enableRotation: false,
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

    return PhotoView(
      imageProvider: MemoryImage(widget.pages[index]),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 2.0,
      enableRotation: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (spreadIndex) {
        widget.onPageChanged(spreadIndex * 2);
      },
      itemCount: (widget.pageCount / 2).ceil(),
      itemBuilder: (context, spreadIndex) {
        final leftIndex = spreadIndex * 2;
        final rightIndex = leftIndex + 1;
        final hasRight = rightIndex < widget.pageCount;
        final primaryIndex = widget.direction == ReaderDirection.rtl && hasRight
            ? rightIndex
            : leftIndex;
        final secondaryIndex = widget.direction == ReaderDirection.rtl && hasRight
            ? leftIndex
            : rightIndex;

        return Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPage(primaryIndex),
                ),
                if (hasRight)
                  Expanded(
                    child: _buildPage(secondaryIndex),
                  )
                else
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'End of story',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    key: const ValueKey('double-page-left-zone'),
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.direction == ReaderDirection.rtl
                        ? _nextSpread
                        : _previousSpread,
                    child: const SizedBox.expand(),
                  ),
                ),
                const Expanded(flex: 30, child: SizedBox.expand()),
                Expanded(
                  flex: 35,
                  child: GestureDetector(
                    key: const ValueKey('double-page-right-zone'),
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.direction == ReaderDirection.rtl
                        ? _previousSpread
                        : _nextSpread,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
