import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../feedback/app_notice.dart';
import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Opens a HOKX-style, in-app video panel without handing playback to another app.
Future<void> showAppVideoPlayer(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    AppNotice.failure(context);
    return;
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (context) => AppVideoPlayerSheet(url: uri, title: title),
  );
}

class AppVideoPlayerSheet extends StatelessWidget {
  const AppVideoPlayerSheet({
    required this.url,
    required this.title,
    super.key,
  });

  final Uri url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Video player' : title;

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
                      displayTitle,
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
            AppVideoPlayerView(url: url, title: title),
          ],
        ),
      ),
    );
  }
}

/// 内嵌视频播放器，既可放在详情页，也可被弹层复用。
class AppVideoPlayerView extends StatefulWidget {
  const AppVideoPlayerView({
    required this.url,
    required this.title,
    this.autoPlay = true,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final Uri url;
  final String title;
  final bool autoPlay;
  final BorderRadius borderRadius;

  @override
  State<AppVideoPlayerView> createState() => _AppVideoPlayerViewState();
}

class _AppVideoPlayerViewState extends State<AppVideoPlayerView> {
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
      if (widget.autoPlay) {
        // 初始化完成后立即播放，避免用户进入播放器后还要再次点击播放。
        try {
          await _controller.play();
        } catch (_) {
          // 某些平台可能暂时拒绝自动播放，但不应把已加载的视频判定为失败。
          try {
            await _controller.pause();
          } catch (_) {
            // 保留播放器界面，让用户仍可重试播放。
          }
        }
      }
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

  Future<void> _openFullscreen() async {
    if (!_isReady || !mounted) return;

    // 先推入播放器，再异步切换系统栏，避免平台通道响应慢时按钮无反馈。
    final fullscreen = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Fullscreen video',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _FullscreenVideoPlayer(
          controller: _controller,
          title: widget.title,
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );

    unawaited(_setSystemUiMode(SystemUiMode.immersiveSticky));
    try {
      await fullscreen;
    } finally {
      unawaited(_setSystemUiMode(SystemUiMode.edgeToEdge));
    }
  }

  Future<void> _setSystemUiMode(SystemUiMode mode) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(mode);
    } catch (_) {
      // 某些桌面平台不支持沉浸式系统栏，但不影响全屏播放器使用。
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final title = widget.title.trim().isEmpty ? 'Video player' : widget.title;

    return Semantics(
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: widget.borderRadius,
            child: AspectRatio(
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
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('video-fullscreen-button'),
                    tooltip: 'Enter fullscreen',
                    onPressed: _openFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenVideoPlayer extends StatelessWidget {
  const _FullscreenVideoPlayer({
    required this.controller,
    required this.title,
    required this.onClose,
  });

  final VideoPlayerController controller;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? 'Video player' : title;
    return Material(
      key: const ValueKey('video-player-fullscreen'),
      color: Colors.black,
      child: SafeArea(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final aspectRatio = value.aspectRatio > 0
                ? value.aspectRatio
                : 16 / 9;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Exit fullscreen',
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(controller),
                          if (!value.isPlaying)
                            Center(
                              child: DecoratedBox(
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
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: VideoProgressIndicator(
                              controller,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                        onPressed: () async {
                          if (value.isPlaying) {
                            await controller.pause();
                          } else {
                            await controller.play();
                          }
                        },
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white70,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        key: const ValueKey('video-exit-fullscreen-button'),
                        tooltip: 'Exit fullscreen',
                        onPressed: onClose,
                        icon: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
            AppLocalizations.of(context).translate('authRequestFailed'),
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
