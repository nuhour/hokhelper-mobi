import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../domain/community_sticker.dart';

const communityPresetEmojis = [
  '🔥',
  '👍',
  '❤️',
  '👏',
  '😂',
  '😮',
  '😢',
  '💯',
  '🎮',
  '⚔️',
  '🛡️',
  '👑',
  '🎯',
  '🏆',
  '💪',
  '⚡',
  '✨',
  '😎',
  '🥳',
  '🤝',
  '🚀',
  '🧠',
  '👀',
  '🙏',
  '😅',
  '🙌',
  '🤖',
  '🫡',
  '📈',
  '📉',
  '🛠️',
  '🎉',
  '🍀',
  '😤',
  '🤔',
  '💥',
  '⏱️',
  '🗺️',
  '🎬',
];

enum CommunityAssetMode { emoji, gif, sticker }

class CommunityGif {
  const CommunityGif({
    required this.url,
    required this.previewUrl,
    required this.name,
  });

  final String url;
  final String previewUrl;
  final String name;
}

class CommunityComposerAssets extends StatefulWidget {
  const CommunityComposerAssets({
    required this.controller,
    required this.loadStickers,
    super.key,
  });

  final TextEditingController controller;
  final Future<List<CommunitySticker>> Function() loadStickers;

  @override
  State<CommunityComposerAssets> createState() =>
      _CommunityComposerAssetsState();
}

class _CommunityComposerAssetsState extends State<CommunityComposerAssets> {
  CommunityAssetMode? _mode;
  Future<List<CommunityGif>>? _gifs;
  Future<List<CommunitySticker>>? _stickers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _AssetButton(
              tooltip: 'GIF',
              icon: Icons.gif_box_outlined,
              selected: _mode == CommunityAssetMode.gif,
              onTap: () => _toggle(CommunityAssetMode.gif),
            ),
            _AssetButton(
              tooltip: 'Emoji',
              icon: Icons.sentiment_satisfied_alt_outlined,
              selected: _mode == CommunityAssetMode.emoji,
              onTap: () => _toggle(CommunityAssetMode.emoji),
            ),
            _AssetButton(
              tooltip: 'HOK stickers',
              icon: Icons.style_outlined,
              selected: _mode == CommunityAssetMode.sticker,
              onTap: () => _toggle(CommunityAssetMode.sticker),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: _mode == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(_mode),
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 190),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      border: Border.all(color: AppTheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPanel(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    return switch (_mode!) {
      CommunityAssetMode.emoji => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: communityPresetEmojis.length,
        itemBuilder: (context, index) {
          final emoji = communityPresetEmojis[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _insert(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 21)),
            ),
          );
        },
      ),
      CommunityAssetMode.gif => FutureBuilder<List<CommunityGif>>(
        future: _gifs,
        builder: (context, snapshot) => _MediaGrid<CommunityGif>(
          values: snapshot.data ?? const [],
          loading: snapshot.connectionState == ConnectionState.waiting,
          imageUrl: (gif) => gif.previewUrl,
          label: (gif) => gif.name,
          onTap: (gif) => _insert('[GIF:${gif.url}]', close: true),
        ),
      ),
      CommunityAssetMode.sticker => FutureBuilder<List<CommunitySticker>>(
        future: _stickers,
        builder: (context, snapshot) => _MediaGrid<CommunitySticker>(
          values: snapshot.data ?? const [],
          loading: snapshot.connectionState == ConnectionState.waiting,
          imageUrl: (sticker) => sticker.imageUrl,
          label: (sticker) => sticker.name,
          onTap: (sticker) =>
              _insert('[STICKER:${sticker.imageUrl}]', close: true),
        ),
      ),
    };
  }

  void _toggle(CommunityAssetMode mode) {
    setState(() {
      _mode = _mode == mode ? null : mode;
      if (_mode == CommunityAssetMode.gif) {
        _gifs ??= _loadGifs();
      } else if (_mode == CommunityAssetMode.sticker) {
        _stickers ??= widget.loadStickers();
      }
    });
  }

  void _insert(String value, {bool close = false}) {
    final controller = widget.controller;
    final selection = controller.selection;
    final offset = selection.isValid ? selection.start : controller.text.length;
    final safeOffset = offset.clamp(0, controller.text.length);
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(safeOffset, safeOffset, value),
      selection: TextSelection.collapsed(offset: safeOffset + value.length),
    );
    if (close) setState(() => _mode = null);
  }
}

class _AssetButton extends StatelessWidget {
  const _AssetButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? AppTheme.gold.withValues(alpha: 0.18)
            : Colors.transparent,
        foregroundColor: selected ? AppTheme.gold : AppTheme.muted,
      ),
      icon: Icon(icon, size: 19),
    );
  }
}

class _MediaGrid<T> extends StatelessWidget {
  const _MediaGrid({
    required this.values,
    required this.loading,
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });

  final List<T> values;
  final bool loading;
  final String Function(T) imageUrl;
  final String Function(T) label;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (values.isEmpty) {
      return const Center(
        child: Text(
          'No media available',
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: values.length,
      itemBuilder: (context, index) {
        final value = values[index];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(value),
          child: AppImage(
            url: imageUrl(value),
            width: double.infinity,
            height: double.infinity,
            borderRadius: 8,
            semanticLabel: label(value),
          ),
        );
      },
    );
  }
}

Future<List<CommunityGif>> _loadGifs() async {
  try {
    final response = await Dio().get<Map<String, dynamic>>(
      'https://tenor.googleapis.com/v2/featured',
      queryParameters: {
        'key': 'LIVDSRZULELA',
        'limit': 36,
        'media_filter': 'minimal',
        'contentfilter': 'medium',
        'locale': 'en_US',
      },
    );
    final results = response.data?['results'];
    if (results is! List) return const [];
    return results
        .map((item) {
          final map = item is Map ? item : const <String, Object?>{};
          final formats = map['media_formats'];
          final formatMap = formats is Map
              ? formats
              : const <String, Object?>{};
          final gif = formatMap['gif'] ?? formatMap['tinygif'];
          final preview = formatMap['tinygif'] ?? formatMap['nanogif'] ?? gif;
          final gifMap = gif is Map ? gif : const <String, Object?>{};
          final previewMap = preview is Map
              ? preview
              : const <String, Object?>{};
          return CommunityGif(
            url: (gifMap['url'] ?? '').toString(),
            previewUrl: (previewMap['url'] ?? gifMap['url'] ?? '').toString(),
            name: (map['content_description'] ?? map['title'] ?? 'GIF')
                .toString(),
          );
        })
        .where((gif) => gif.url.isNotEmpty)
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
