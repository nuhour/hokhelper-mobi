import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/hok_helper_app.dart';
import 'src/features/home/presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 共享容器让首页请求在 Flutter 首帧前启动，StartupSplash 会复用同一个 Future。
  final container = ProviderContainer();
  unawaited(
    container
        .read(homeStatsProvider.future)
        .then<void>((_) {})
        .catchError((Object _) {}),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: HokHelperApp()),
  );
}
