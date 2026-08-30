import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hok_helper_mobile/src/core/widgets/app_video_player_sheet.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams = {};
  var createCalls = 0;
  var _nextPlayerId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final playerId = _nextPlayerId++;
    createCalls += 1;
    final stream = StreamController<VideoEvent>();
    _streams[playerId] = stream;
    stream.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 2),
        size: const Size(1920, 1080),
      ),
    );
    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _streams[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    await _streams.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => Texture(textureId: playerId);
}

void main() {
  testWidgets('opens a fullscreen player without creating a second video', (
    tester,
  ) async {
    final originalPlatform = VideoPlayerPlatform.instance;
    final fakePlatform = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakePlatform;
    addTearDown(() => VideoPlayerPlatform.instance = originalPlatform);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppVideoPlayerView(
            url: Uri.parse('https://example.test/cg.mp4'),
            title: 'CG video',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fullscreenButton = find.byKey(
      const ValueKey('video-fullscreen-button'),
    );
    expect(fullscreenButton, findsOneWidget);
    expect(fakePlatform.createCalls, 1);

    await tester.tap(fullscreenButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('video-player-fullscreen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('video-exit-fullscreen-button')),
      findsOneWidget,
    );
    expect(fakePlatform.createCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey('video-exit-fullscreen-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('video-player-fullscreen')), findsNothing);
  });
}
