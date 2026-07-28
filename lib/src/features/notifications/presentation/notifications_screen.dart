import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/app_time_formatter.dart';
import '../../../core/i18n/app_localizations.dart';
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
  const NotificationsScreen({this.showPageHeader = true, super.key});

  final bool showPageHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);

    return Material(
      color: context.hokTheme.backgroundDeep,
      child: AppAsyncView<AuthUser?>(
        value: authValue,
        data: (user) {
          if (user == null) {
            return _SignedOutNotifications(showPageHeader: showPageHeader);
          }

          return _SignedInNotifications(showPageHeader: showPageHeader);
        },
      ),
    );
  }
}

class _SignedOutNotifications extends StatelessWidget {
  const _SignedOutNotifications({required this.showPageHeader});

  final bool showPageHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (showPageHeader) const SizedBox(height: 80),
        AppEmptyState(
          icon: Icons.notifications_none_outlined,
          title: l10n.translate('notificationsLoginTitle'),
          message: l10n.translate('notificationsLoginMessage'),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: Text(l10n.translate('notificationsLogin')),
          ),
        ),
      ],
    );
  }
}

class _SignedInNotifications extends ConsumerStatefulWidget {
  const _SignedInNotifications({required this.showPageHeader});

  final bool showPageHeader;

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
    final l10n = AppLocalizations.of(context);
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
                      if (widget.showPageHeader)
                        Expanded(
                          child: AppSectionHeader(
                            title: l10n.translate('notificationsTitle'),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: notifications.isEmpty ? null : _markAllRead,
                        icon: const Icon(Icons.done_all, size: 18),
                        label: Text(l10n.translate('notificationsMarkAllRead')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.format('notificationsUnread', {
                      'count': '$unreadCount',
                    }),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: unreadCount == 0
                          ? context.hokTheme.onSurfaceMuted
                          : AppTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (notifications.isEmpty)
                    AppEmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: l10n.translate('notificationsEmptyTitle'),
                      message: l10n.translate('notificationsEmptyMessage'),
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
                          _isLoadingMore
                              ? l10n.translate('notificationsLoading')
                              : l10n.translate('notificationsLoadMore'),
                        ),
                      ),
                    ),
                  ],
                  if (page.total > 0) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.format('notificationsCount', {
                        'count': '${page.total}',
                      }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.hokTheme.onSurfaceMuted,
                      ),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).format('notificationsLoadMoreFailed', {
              'error': error.toString(),
            }),
          ),
        ),
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
  final link = normalizePortalLinkTarget(notification.link);
  final isCommunityPostLike = link.isEmpty || link.contains('/community/post/');
  if (isLike && notification.actorId > 0 && isCommunityPostLike) {
    return '/profile/${notification.actorId}';
  }

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
    final l10n = AppLocalizations.of(context);
    final displayText = _resolveNotificationText(notification, l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: notification.isRead
            ? context.hokTheme.surfaceSlate
            : context.hokTheme.surfaceRaised,
        border: Border.all(
          color: notification.isRead
              ? context.hokTheme.outlineSoft
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
                                color: context.hokTheme.onSurfaceStrong,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.hokTheme.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppTimeFormatter.relative(
                          context,
                          notification.createdAt,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.hokTheme.onSurfaceMuted,
                        ),
                      ),
                      if (notification.link.isNotEmpty)
                        TextButton(
                          onPressed: () => onView(context),
                          child: Text(l10n.translate('notificationsView')),
                        ),
                      if (!notification.isRead)
                        TextButton(
                          onPressed: onMarkRead,
                          child: Text(l10n.translate('notificationsMarkRead')),
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
  AppLocalizations l10n,
) {
  final actorName = notification.actorName.trim().isNotEmpty
      ? notification.actorName.trim()
      : l10n.translate('notificationSomeone');
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
      title: l10n.translate('notificationGenericTitle'),
      content: level == null
          ? l10n.translate('notificationReachedNewLevel')
          : l10n.format('notificationReachedLevel', {'level': level}),
    );
  }

  final isFollow =
      sourceType.contains('follow') ||
      _hasAny(classifier, const ['关注', 'follow', 'follower']);
  if (isFollow) {
    return _NotificationDisplayText(
      title: l10n.translate('notificationGenericTitle'),
      content: l10n.format('notificationFollowedYou', {'actor': actorName}),
    );
  }

  final isComment =
      sourceType.contains('comment') ||
      _hasAny(classifier, const ['评论', 'comment', 'reply', 'replied', '回复']);
  if (isComment) {
    return _NotificationDisplayText(
      title: l10n.translate('notificationGenericTitle'),
      content: l10n.format('notificationCommentedOnPost', {'actor': actorName}),
    );
  }

  final isFavorite =
      sourceType.contains('favorite') ||
      _hasAny(classifier, const ['收藏', 'favorite', 'favourite', 'saved']);
  if (isFavorite) {
    final item = _targetItemLabel(sourceType, link, l10n);
    return _NotificationDisplayText(
      title: l10n.translate('notificationGenericTitle'),
      content: l10n.format('notificationFavorited', {
        'actor': actorName,
        'item': item,
      }),
    );
  }

  final isLike =
      sourceType.contains('like') ||
      _hasAny(classifier, const ['点赞', 'like', 'liked']);
  if (isLike) {
    final item = _targetItemLabel(sourceType, link, l10n);
    return _NotificationDisplayText(
      title: l10n.translate('notificationGenericTitle'),
      content: l10n.format('notificationLiked', {
        'actor': actorName,
        'item': item,
      }),
    );
  }

  if (forceFallback) {
    return _NotificationDisplayText(
      title: l10n.translate('notificationGenericTitle'),
      content: '',
    );
  }

  return _NotificationDisplayText(
    title: title.isEmpty ? l10n.translate('notificationGenericTitle') : title,
    content: content,
  );
}

bool _containsChinese(String value) {
  return RegExp(r'[\u3400-\u9fff]').hasMatch(value);
}

bool _hasAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}

String _targetItemLabel(String sourceType, String link, AppLocalizations l10n) {
  if (sourceType.contains('build') || link.contains('/tools/build-sim')) {
    return l10n.translate('notificationItemBuild');
  }
  if (sourceType.contains('prompt') || link.contains('/tools/prompts')) {
    return l10n.translate('notificationItemPrompt');
  }
  if (sourceType.contains('post') || link.contains('/community/post/')) {
    return l10n.translate('notificationItemPost');
  }
  return l10n.translate('notificationItemContent');
}
