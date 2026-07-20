import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Opens a HOKX-style, in-app video panel without handing playback to another app.
Future<void> showAppVideoPlayer(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Video is unavailable')));
    return;
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (context) => AppVideoPlayerSheet(url: uri, title: title),
  );
}

class AppVideoPlayerSheet extends StatefulWidget {
  const AppVideoPlayerSheet({
    required this.url,
    required this.title,
    super.key,
  });

  final Uri url;
  final String title;

  @override
  State<AppVideoPlayerSheet> createState() => _AppVideoPlayerSheetState();
}

class _AppVideoPlayerSheetState extends State<AppVideoPlayerSheet> {
  late final VideoPlayerController _controller;
  var _isReady = false;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.url);
    _initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      _controller.addListener(_refresh);
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayback() async {
    if (!_isReady) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final title = widget.title.trim().isEmpty ? 'Video player' : widget.title;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      backgroundColor: context.hokTheme.surfaceSlate,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: AppTheme.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.hokTheme.onSurfaceStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close video',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            AspectRatio(
              aspectRatio: _isReady && value.aspectRatio > 0
                  ? value.aspectRatio
                  : 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child: _hasError
                    ? const _VideoUnavailable()
                    : !_isReady
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.gold),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _togglePlayback,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            if (!value.isPlaying)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.56),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppTheme.gold,
                                  bufferedColor: Color(0x88FFFFFF),
                                  backgroundColor: Color(0x55000000),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            if (_isReady)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                      onPressed: _togglePlayback,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    Text(
                      '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.hokTheme.onSurfaceMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_file_outlined,
            size: 34,
            color: context.hokTheme.onSurfaceMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Video is unavailable',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.hokTheme.onSurfaceMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final totalSeconds = value.inSeconds.clamp(0, 359999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final secondsText = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$secondsText';
  }
  return '${minutes.toString().padLeft(2, '0')}:$secondsText';
}
