import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
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

class _SignedInNotifications extends ConsumerWidget {
  const _SignedInNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsValue = ref.watch(notificationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
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
              final unreadCount = page.rows
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
                        onPressed: page.rows.isEmpty
                            ? null
                            : () => _markAllRead(ref),
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
                  if (page.rows.isEmpty)
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
                      itemCount: page.rows.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NotificationCard(
                          notification: page.rows[index],
                          onMarkRead: () => _markRead(ref, page.rows[index].id),
                        );
                      },
                    ),
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

  Future<void> _markRead(WidgetRef ref, int id) async {
    await ref.read(notificationsRepositoryProvider).markRead([id]);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    ref.invalidate(notificationsProvider);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
  });

  final NotificationSummary notification;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      'growth' => Icons.auto_awesome,
      _ when notification.targetType.contains('follow') => Icons.person_add_alt,
      _ => Icons.chat_bubble_outline,
    };

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
                          notification.title,
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
                    notification.content,
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
                          onPressed: () => _openLink(context),
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

  void _openLink(BuildContext context) {
    final link = notification.link.trim();
    if (!link.startsWith('/')) {
      return;
    }
    context.push(link);
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

String _formatTime(String value) {
  if (value.isEmpty) {
    return '';
  }
  return value.replaceFirst('T', ' ').replaceFirst(RegExp(r'\.\d+Z?$'), '');
}
