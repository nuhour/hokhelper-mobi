import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.width,
    this.height,
    this.aspectRatio,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    super.key,
  });

  static const double defaultAspectRatio = 1;

  final String? url;
  final BoxFit fit;
  final double borderRadius;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    final label = semanticLabel?.trim();
    final ratio = aspectRatio ?? defaultAspectRatio;
    final resolvedWidth = width ?? (height == null ? null : height! * ratio);
    final resolvedHeight = height ?? (width == null ? null : width! / ratio);

    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl == null || imageUrl.isEmpty
          ? _ImagePlaceholder(borderRadius: borderRadius)
          : CachedNetworkImage(
              imageUrl: imageUrl,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              progressIndicatorBuilder: (context, url, progress) =>
                  _ImagePlaceholder(
                    borderRadius: borderRadius,
                    progress: progress.progress,
                  ),
              errorWidget: (context, url, error) =>
                  _ImagePlaceholder(borderRadius: borderRadius, isError: true),
            ),
    );

    if (width == null && height == null) {
      image = AspectRatio(aspectRatio: ratio, child: image);
    }

    if (resolvedWidth != null || resolvedHeight != null) {
      image = SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: image,
      );
    }

    if (excludeFromSemantics) {
      return ExcludeSemantics(child: image);
    }

    if (label == null || label.isEmpty) {
      return image;
    }

    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: image),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.borderRadius,
    this.progress,
    this.isError = false,
  });

  final double borderRadius;
  final double? progress;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: isError
          ? const Icon(Icons.broken_image_outlined, color: AppTheme.muted)
          : progress == null
          ? const Icon(
              Icons.image_not_supported_outlined,
              color: AppTheme.muted,
            )
          : CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: AppTheme.gold,
            ),
    );
  }
}
