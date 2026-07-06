import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/routing/portal_link.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notifications_repository.dart';
import '../domain/notification_summary.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

final notificationsProvider = FutureProvider<NotificationPage>((ref) {
  return ref.watch(notificationsRepositoryProvider).loadNotifications();
});

const _notificationsPageSize = 50;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);

    return Material(
      color: AppTheme.bg,
      child: AppAsyncView<AuthUser?>(
        value: authValue,
        data: (user) {
          if (user == null) {
            return const _SignedOutNotifications();
          }

          return const _SignedInNotifications();
        },
      ),
    );
  }
}

class _SignedOutNotifications extends StatelessWidget {
  const _SignedOutNotifications();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(title: 'Notifications'),
        const SizedBox(height: 80),
        const AppEmptyState(
          icon: Icons.notifications_none_outlined,
          title: 'Login to view notifications',
          message:
              'Your comments, follows, likes, and level updates live here.',
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ),
      ],
    );
  }
}

class _SignedInNotifications extends ConsumerStatefulWidget {
  const _SignedInNotifications();

  @override
  ConsumerState<_SignedInNotifications> createState() =>
      _SignedInNotificationsState();
}

class _SignedInNotificationsState
    extends ConsumerState<_SignedInNotifications> {
  final _extraNotifications = <NotificationSummary>[];
  var _nextPage = 2;
  var _isLoadingMore = false;
  var _hasMore = true;

  @override
  Widget build(BuildContext context) {
    final notificationsValue = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        _resetLoadedPages();
        ref.invalidate(notificationsProvider);
        await ref.read(notificationsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          AppAsyncView<NotificationPage>(
            value: notificationsValue,
            retry: () => ref.invalidate(notificationsProvider),
            data: (page) {
              final notifications = [...page.rows, ..._extraNotifications];
              final unreadCount = notifications
                  .where((notification) => !notification.isRead)
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: AppSectionHeader(title: 'Notifications'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: notifications.isEmpty ? null : _markAllRead,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$unreadCount unread',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: unreadCount == 0 ? AppTheme.muted : AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (notifications.isEmpty)
                    const AppEmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'No notifications yet',
                      message:
                          'Community and growth activity will appear here.',
                    )
                  else
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NotificationCard(
                          notification: notifications[index],
                          onMarkRead: () => _markRead(notifications[index].id),
                          onView: (cardContext) => _viewNotification(
                            cardContext,
                            notifications[index],
                          ),
                        );
                      },
                    ),
                  if (_hasMore && notifications.length < page.total) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _isLoadingMore ? null : _loadMore,
                        icon: _isLoadingMore
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          _isLoadingMore ? 'Loading...' : 'Load more',
                        ),
                      ),
                    ),
                  ],
                  if (page.total > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      '${page.total} notifications',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(int id) async {
    await ref.read(notificationsRepositoryProvider).markRead([id]);
    _resetLoadedPages();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _viewNotification(
    BuildContext context,
    NotificationSummary notification,
  ) async {
    final destination = _resolveNotificationDestination(notification);
    final router = GoRouter.of(context);
    if (!notification.isRead) {
      await ref.read(notificationsRepositoryProvider).markRead([
        notification.id,
      ]);
    }

    if (destination == null) {
      _resetLoadedPages();
      ref.invalidate(notificationsProvider);
      return;
    }
    router.go(destination);
    _resetLoadedPages();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    _resetLoadedPages();
    ref.invalidate(notificationsProvider);
  }

  void _resetLoadedPages() {
    _extraNotifications.clear();
    _nextPage = 2;
    _hasMore = true;
    _isLoadingMore = false;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    setState(() => _isLoadingMore = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final nextPage = await ref
          .read(notificationsRepositoryProvider)
          .loadNotifications(page: _nextPage, pageSize: _notificationsPageSize);
      if (!mounted) {
        return;
      }

      setState(() {
        _nextPage += 1;
        _extraNotifications.addAll(nextPage.rows);
        _hasMore = nextPage.rows.length >= _notificationsPageSize;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load more notifications: $error')),
      );
    }
  }
}

String? _resolveNotificationDestination(NotificationSummary notification) {
  final classifier =
      '${notification.targetType} ${notification.title} ${notification.content}'
          .toLowerCase();
  final isLike =
      classifier.contains('like') ||
      classifier.contains('liked') ||
      classifier.contains('点赞');
  if (isLike && notification.actorId > 0) {
    return '/profile/${notification.actorId}';
  }

  final link = normalizePortalLinkTarget(notification.link);
  if (link.startsWith(RegExp('https?://', caseSensitive: false))) {
    return externalLinkRoute(link);
  }
  if (!link.startsWith('/')) {
    return null;
  }
  return link;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
    required this.onView,
  });

  final NotificationSummary notification;
  final VoidCallback onMarkRead;
  final void Function(BuildContext context) onView;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      'growth' => Icons.auto_awesome,
      _ when notification.targetType.contains('follow') => Icons.person_add_alt,
      _ => Icons.chat_bubble_outline,
    };
    final displayText = _resolveNotificationText(notification);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: notification.isRead ? AppTheme.panel : AppTheme.panelAlt,
        border: Border.all(
          color: notification.isRead
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.gold.withValues(alpha: 0.24),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(
              icon: icon,
              avatarUrl: notification.actorAvatar,
              label: notification.actorName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        const _UnreadDot(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayText.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _formatTime(notification.createdAt),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                      if (notification.link.isNotEmpty)
                        TextButton(
                          onPressed: () => onView(context),
                          child: const Text('View'),
                        ),
                      if (!notification.isRead)
                        TextButton(
                          onPressed: onMarkRead,
                          child: const Text('Mark read'),
                        ),
                    ],
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

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.icon,
    required this.avatarUrl,
    required this.label,
  });

  final IconData icon;
  final String avatarUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return AppImage(
        url: avatarUrl,
        width: 42,
        height: 42,
        borderRadius: 14,
        semanticLabel: label,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: AppTheme.gold, size: 21),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(width: 8, height: 8),
    );
  }
}

class _NotificationDisplayText {
  const _NotificationDisplayText({required this.title, required this.content});

  final String title;
  final String content;
}

_NotificationDisplayText _resolveNotificationText(
  NotificationSummary notification,
) {
  final actorName = notification.actorName.trim().isNotEmpty
      ? notification.actorName.trim()
      : 'Someone';
  final title = notification.title;
  final content = notification.content;
  final classifier = '${notification.targetType} $title $content'.toLowerCase();
  final link = notification.link.toLowerCase();
  final forceFallback = _containsChinese(title) || _containsChinese(content);
  final sourceType = notification.targetType.toLowerCase();

  if (notification.type == 'growth') {
    final levelMatch = RegExp(
      r'lv\.?\s*(\d+)|(\d+)',
      caseSensitive: false,
    ).firstMatch('$title $content');
    final level = levelMatch?.group(1) ?? levelMatch?.group(2);
    return _NotificationDisplayText(
      title: 'Notification',
      content: level == null
          ? 'You reached a new level'
          : 'You reached Lv.$level',
    );
  }

  final isFollow =
      sourceType.contains('follow') ||
      _hasAny(classifier, const ['关注', 'follow', 'follower']);
  if (isFollow) {
    return _NotificationDisplayText(
      title: 'Notification',
      content: '$actorName followed you',
    );
  }

  final isComment =
      sourceType.contains('comment') ||
      _hasAny(classifier, const ['评论', 'comment', 'reply', 'replied', '回复']);
  if (isComment) {
    return _NotificationDisplayText(
      title: 'Notification',
      content: '$actorName commented on your post',
    );
  }

  final isFavorite =
      sourceType.contains('favorite') ||
      _hasAny(classifier, const ['收藏', 'favorite', 'favourite', 'saved']);
  if (isFavorite) {
    final item = _targetItemLabel(sourceType, link);
    return _NotificationDisplayText(
      title: 'Notification',
      content: '$actorName favorited your $item',
    );
  }

  final isLike =
      sourceType.contains('like') ||
      _hasAny(classifier, const ['点赞', 'like', 'liked']);
  if (isLike) {
    final item = _targetItemLabel(sourceType, link);
    return _NotificationDisplayText(
      title: 'Notification',
      content: '$actorName liked your $item',
    );
  }

  if (forceFallback) {
    return const _NotificationDisplayText(title: 'Notification', content: '');
  }

  return _NotificationDisplayText(
    title: title.isEmpty ? 'Notification' : title,
    content: content,
  );
}

bool _containsChinese(String value) {
  return RegExp(r'[\u3400-\u9fff]').hasMatch(value);
}

bool _hasAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}

String _targetItemLabel(String sourceType, String link) {
  if (sourceType.contains('build') || link.contains('/tools/build-sim')) {
    return 'build';
  }
  if (sourceType.contains('prompt') || link.contains('/tools/prompts')) {
    return 'prompt';
  }
  if (sourceType.contains('post') || link.contains('/community/post/')) {
    return 'post';
  }
  return 'content';
}

String _formatTime(String value) {
  if (value.isEmpty) {
    return '';
  }
  return value.replaceFirst('T', ' ').replaceFirst(RegExp(r'\.\d+Z?$'), '');
}
