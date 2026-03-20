import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/image_cache.dart';
import '../data/comic_downloader.dart';
import '../services/page_cache_manager.dart';

class StreamingPageImage extends ConsumerStatefulWidget {
  const StreamingPageImage({
    required this.pageUrl,
    this.thumbnailUrl,
    this.headers,
    this.fit = BoxFit.contain,
    this.pageLoader,
    super.key,
  });

  final String pageUrl;
  final String? thumbnailUrl;
  final Map<String, String>? headers;
  final BoxFit fit;
  final Future<Uint8List?> Function()? pageLoader;

  @override
  ConsumerState<StreamingPageImage> createState() => _StreamingPageImageState();
}

class _StreamingPageImageState extends ConsumerState<StreamingPageImage> {
  static const Duration _spinnerDelay = Duration(milliseconds: 500);

  Future<Uint8List?>? _thumbnailFuture;
  Future<Uint8List?>? _pageFuture;
  Timer? _spinnerTimer;
  bool _showSpinner = false;
  bool _didLoad = false;
  bool _hasError = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _beginAttempt();
  }

  @override
  void didUpdateWidget(covariant StreamingPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageUrl != widget.pageUrl ||
        oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _attempt = 0;
      _beginAttempt();
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _beginAttempt() {
    _spinnerTimer?.cancel();
    _didLoad = false;
    _showSpinner = false;
    _hasError = false;
    _spinnerTimer = Timer(_spinnerDelay, () {
      if (!mounted || _didLoad) {
        return;
      }
      setState(() {
        _showSpinner = true;
      });
    });

    final thumbnailUrl = widget.thumbnailUrl;
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      _thumbnailFuture = ref
          .read(imageCacheStoreProvider)
          .getThumbnailBytes(thumbnailUrl, headers: widget.headers);
    } else {
      _thumbnailFuture = Future<Uint8List?>.value(null);
    }

    _pageFuture = _loadPageBytes();
  }

  Future<Uint8List?> _loadPageBytes() async {
    if (widget.pageLoader != null) {
      return widget.pageLoader!();
    }

    final cache = ref.read(pageCacheManagerProvider);
    final cached = cache.get(widget.pageUrl);
    if (cached != null) {
      return cached;
    }

    final bytes = await ref.read(comicDownloaderProvider).downloadBytesWithHeaders(
      Uri.parse(widget.pageUrl),
      headers: widget.headers,
    );
    if (bytes.isEmpty) {
      return null;
    }

    final pageBytes = Uint8List.fromList(bytes);
    cache.put(widget.pageUrl, pageBytes);
    return pageBytes;
  }

  void _markLoaded() {
    if (_didLoad) {
      return;
    }
    _spinnerTimer?.cancel();
    setState(() {
      _didLoad = true;
      _showSpinner = false;
    });
  }

  void _markError() {
    _spinnerTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _showSpinner = false;
      _hasError = true;
    });
  }

  void _retry() {
    setState(() {
      _attempt += 1;
      _beginAttempt();
    });
  }

  Widget _buildFallbackPlaceholder() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white54,
          size: 42,
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _buildFallbackPlaceholder();
        }
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
        );
      },
    );
  }

  Widget _buildErrorOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 34),
            const SizedBox(height: 8),
            const Text(
              'Failed to load page',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildThumbnailPlaceholder(),
        if (!_hasError)
          FutureBuilder<Uint8List?>(
            future: _pageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markError();
                  });
                  return const SizedBox.expand();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markLoaded();
                });
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  child: Image.memory(
                    snapshot.data!,
                    key: ValueKey('${widget.pageUrl}#$_attempt'),
                    fit: widget.fit,
                    gaplessPlayback: true,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              }

              return const SizedBox.expand();
            },
          ),
        if (_hasError) _buildErrorOverlay(),
        if (_showSpinner)
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
