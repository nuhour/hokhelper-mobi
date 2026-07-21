import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLaneIcon extends StatelessWidget {
  const AppLaneIcon({
    required this.assetName,
    this.size = 20,
    this.color,
    super.key,
  });

  final String assetName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/lane-icons/$assetName.png',
      width: size,
      height: size,
      color: color ?? context.hokTheme.onSurfaceStrong,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );
  }
}
