import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

FaIconData? appPlatformFaIconData(String platform) {
  return switch (platform.trim().toLowerCase()) {
    'x' || 'twitter' => FontAwesomeIcons.xTwitter,
    'instagram' => FontAwesomeIcons.instagram,
    'facebook' => FontAwesomeIcons.facebookF,
    'telegram' => FontAwesomeIcons.telegram,
    'tiktok' => FontAwesomeIcons.tiktok,
    'reddit' => FontAwesomeIcons.redditAlien,
    'discord' => FontAwesomeIcons.discord,
    'youtube' => FontAwesomeIcons.youtube,
    'whatsapp' => FontAwesomeIcons.whatsapp,
    'wechat' || 'weixin' => FontAwesomeIcons.weixin,
    _ => null,
  };
}

class AppPlatformIcon extends StatelessWidget {
  const AppPlatformIcon({
    required this.platform,
    this.color,
    this.size = 18,
    super.key,
  });

  final String platform;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = appPlatformFaIconData(platform);
    return icon == null
        ? Icon(Icons.public_outlined, color: color, size: size)
        : FaIcon(icon, color: color, size: size);
  }
}
