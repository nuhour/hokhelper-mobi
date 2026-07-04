import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/info_repository.dart';
import '../domain/friend_link_summary.dart';

final infoRepositoryProvider = Provider<InfoRepository>((ref) {
  return InfoRepository(apiClient: ref.watch(apiClientProvider));
});

final friendLinksProvider = FutureProvider<List<FriendLinkSummary>>((ref) {
  return ref.watch(infoRepositoryProvider).loadFriendLinks();
});

class InfoCenterScreen extends ConsumerWidget {
  const InfoCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(friendLinksProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Info Center'),
            const SizedBox(height: 8),
            Text(
              'HOK Helper platform information, support policies, and partner links.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            const _AboutCard(),
            const SizedBox(height: 12),
            const _FaqCard(),
            const SizedBox(height: 12),
            const _PolicyCard(
              icon: Icons.lock_outline,
              title: 'Privacy Policy',
              body:
                  'HOK Helper collects minimal identifiers for account sync, preferences, analytics, and optional AI prompt usage. Data is used to improve the assistant experience and is not sold.',
            ),
            const SizedBox(height: 12),
            const _PolicyCard(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              body:
                  'Use HOK Helper as a strategy reference. Community conduct, AI prompt usage, and shared content must stay respectful and lawful. The project is independent from the game publisher.',
            ),
            const SizedBox(height: 20),
            _FriendLinksSection(value: ref.watch(friendLinksProvider)),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.shield_outlined,
      title: 'About HOK Helper',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BodyText(
            'Global Community Intel & Strategy for Honor of Kings players.',
          ),
          SizedBox(height: 12),
          _BulletText('Cross-region meta analysis and hero trend tracking'),
          _BulletText('Community-driven build and draft tools'),
          _BulletText('Multi-language support for EN, ZH, and ID players'),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard();

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.help_outline,
      title: 'FAQ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _QuestionAnswer(
            question: 'Where does hero data come from?',
            answer:
                'Stats are read from public game and HOK Helper backend sources, then normalized for region-aware mobile views.',
          ),
          SizedBox(height: 12),
          _QuestionAnswer(
            question: 'Is this an official product?',
            answer:
                'No. HOK Helper is an independent community assistant built for strategy learning and discussion.',
          ),
          SizedBox(height: 12),
          _QuestionAnswer(
            question: 'How do I report incorrect data?',
            answer:
                'Use the community channels or support contact listed by the portal team.',
          ),
        ],
      ),
    );
  }
}

class _FriendLinksSection extends ConsumerWidget {
  const _FriendLinksSection({required this.value});

  final AsyncValue<List<FriendLinkSummary>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InfoPanel(
      icon: Icons.link_outlined,
      title: 'Friend Links',
      child: AppAsyncView<List<FriendLinkSummary>>(
        value: value,
        retry: () => ref.invalidate(friendLinksProvider),
        data: (links) {
          if (links.isEmpty) {
            return const AppEmptyState(
              icon: Icons.link_off_outlined,
              title: 'No links found',
              message: 'Pull to refresh once partner links are available.',
            );
          }

          return Column(
            children: [
              for (final link in links) ...[
                _FriendLinkCard(link: link),
                if (link != links.last) const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FriendLinkCard extends StatelessWidget {
  const _FriendLinkCard({required this.link});

  final FriendLinkSummary link;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AppImage(
              url: link.logoUrl,
              width: 44,
              height: 44,
              borderRadius: 10,
              semanticLabel: link.name,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.name.isEmpty ? 'Partner Site' : link.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (link.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      link.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(icon: icon, title: title, child: _BodyText(body));
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _QuestionAnswer extends StatelessWidget {
  const _QuestionAnswer({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        _BodyText(answer),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: AppTheme.gold),
          ),
          const SizedBox(width: 8),
          Expanded(child: _BodyText(text)),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted, height: 1.45),
    );
  }
}
