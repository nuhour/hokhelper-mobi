import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_platform_icon.dart';

String buildAppShareText(
  BuildContext context, {
  required String content,
  String? url,
}) {
  final sourceAttribution = AppLocalizations.of(
    context,
  ).translate('shareSourceAttribution');
  return [
    if (content.trim().isNotEmpty) content.trim(),
    if (url?.trim().isNotEmpty == true) url!.trim(),
    sourceAttribution,
  ].join('\n\n');
}

Future<void> showAppShareSheet(
  BuildContext context, {
  required String title,
  required String url,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AppShareSheet(title: title, url: url),
  );
}

class _AppShareSheet extends StatelessWidget {
  const _AppShareSheet({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final sharedTitle = buildAppShareText(context, content: title);
    final copiedMessage = buildAppShareText(context, content: title, url: url);

    return SafeArea(
      top: false,
      child: Material(
        color: context.hokTheme.surfaceSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          side: BorderSide(color: context.hokTheme.outlineSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.hokTheme.onSurfaceMuted.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Share',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.hokTheme.onSurfaceStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ShareTarget(
                    label: 'X',
                    icon: AppPlatformIcon(
                      platform: 'x',
                      color: context.hokTheme.onSurfaceStrong,
                      size: 22,
                    ),
                    color: context.hokTheme.onSurfaceStrong,
                    onTap: () => _open(
                      context,
                      'https://x.com/intent/tweet?text=${Uri.encodeComponent(sharedTitle)}&url=${Uri.encodeComponent(url)}',
                    ),
                  ),
                  _ShareTarget(
                    label: 'Instagram',
                    icon: const AppPlatformIcon(
                      platform: 'instagram',
                      color: Color(0xFFEC4899),
                      size: 22,
                    ),
                    color: const Color(0xFFEC4899),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: copiedMessage),
                      );
                      if (context.mounted) {
                        await _open(context, 'https://www.instagram.com/');
                      }
                    },
                  ),
                  _ShareTarget(
                    label: 'Facebook',
                    icon: const AppPlatformIcon(
                      platform: 'facebook',
                      color: Color(0xFF3B82F6),
                      size: 22,
                    ),
                    color: const Color(0xFF3B82F6),
                    onTap: () => _open(
                      context,
                      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}&quote=${Uri.encodeComponent(sharedTitle)}',
                    ),
                  ),
                  _ShareTarget(
                    label: 'Reddit',
                    icon: const AppPlatformIcon(
                      platform: 'reddit',
                      color: Color(0xFFF97316),
                      size: 22,
                    ),
                    color: const Color(0xFFF97316),
                    onTap: () => _open(
                      context,
                      'https://www.reddit.com/submit?title=${Uri.encodeComponent(sharedTitle)}&url=${Uri.encodeComponent(url)}',
                    ),
                  ),
                  _ShareTarget(
                    label: 'Copy',
                    icon: const Icon(Icons.link_rounded, size: 22),
                    color: AppTheme.gold,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: copiedMessage),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String target) async {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: icon,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.hokTheme.onSurfaceMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
