import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            const _AboutCard(onTapRoute: '/about'),
            const SizedBox(height: 12),
            const _FaqCard(onTapRoute: '/faq'),
            const SizedBox(height: 12),
            const _PolicyCard(
              icon: Icons.lock_outline,
              title: 'Privacy Policy',
              onTapRoute: '/privacy',
              body:
                  'HOK Helper collects minimal identifiers for account sync, preferences, analytics, and optional AI prompt usage. Data is used to improve the assistant experience and is not sold.',
            ),
            const SizedBox(height: 12),
            const _PolicyCard(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTapRoute: '/terms',
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

class InfoStaticPage extends ConsumerWidget {
  const InfoStaticPage({
    required this.section,
    this.highlightCommunity = false,
    super.key,
  });

  final InfoStaticSection section;
  final bool highlightCommunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info')),
      body: RefreshIndicator(
        onRefresh: () {
          if (section == InfoStaticSection.links) {
            return ref.refresh(friendLinksProvider.future);
          }
          return Future<void>.value();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: _StaticSectionBody(
            section: section,
            highlightCommunity: highlightCommunity,
          ),
        ),
      ),
    );
  }
}

enum InfoStaticSection {
  about('About HOK Helper'),
  faq('FAQ'),
  privacy('Privacy Policy'),
  terms('Terms of Service'),
  links('Friend Links');

  const InfoStaticSection(this.title);

  final String title;
}

class _StaticSectionBody extends ConsumerWidget {
  const _StaticSectionBody({
    required this.section,
    required this.highlightCommunity,
  });

  final InfoStaticSection section;
  final bool highlightCommunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section != InfoStaticSection.links) ...[
          AppSectionHeader(title: section.title),
          const SizedBox(height: 12),
        ],
        switch (section) {
          InfoStaticSection.about => _AboutDetail(
            highlightCommunity: highlightCommunity,
          ),
          InfoStaticSection.faq => const _FaqDetail(),
          InfoStaticSection.privacy => const _PrivacyDetail(),
          InfoStaticSection.terms => const _TermsDetail(),
          InfoStaticSection.links => _FriendLinksSection(
            value: ref.watch(friendLinksProvider),
          ),
        },
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({this.onTapRoute});

  final String? onTapRoute;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.shield_outlined,
      title: 'About HOK Helper',
      onTapRoute: onTapRoute,
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
  const _FaqCard({this.onTapRoute});

  final String? onTapRoute;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.help_outline,
      title: 'FAQ',
      onTapRoute: onTapRoute,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _showFriendLinkApplySheet(context),
              icon: const Icon(Icons.add_link),
              label: const Text('Apply for link'),
            ),
          ),
          const SizedBox(height: 14),
          AppAsyncView<List<FriendLinkSummary>>(
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
        ],
      ),
    );
  }

  void _showFriendLinkApplySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _FriendLinkApplySheet(),
    );
  }
}

class _FriendLinkApplySheet extends ConsumerStatefulWidget {
  const _FriendLinkApplySheet();

  @override
  ConsumerState<_FriendLinkApplySheet> createState() =>
      _FriendLinkApplySheetState();
}

class _FriendLinkApplySheetState extends ConsumerState<_FriendLinkApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_link, color: AppTheme.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Link exchange',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Site name',
                  hintText: 'HOK Lab',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Site name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Portal URL',
                  hintText: 'www.example.com',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Portal URL is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Brief description',
                  hintText: 'Draft tools and hero research.',
                ),
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send application'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final url = _normalizePortalUrl(_urlController.text);

    try {
      await ref
          .read(infoRepositoryProvider)
          .applyFriendLink(
            name: _nameController.text.trim(),
            url: url,
            description: _descriptionController.text.trim(),
          );
      ref.invalidate(friendLinksProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Friend link application submitted')),
      );
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Application failed: $error')),
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _normalizePortalUrl(String value) {
    final trimmed = value.trim();
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }
    return 'https://$trimmed';
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
    this.onTapRoute,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? onTapRoute;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: icon,
      title: title,
      onTapRoute: onTapRoute,
      child: _BodyText(body),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.onTapRoute,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? onTapRoute;

  @override
  Widget build(BuildContext context) {
    final route = onTapRoute;
    final panel = DecoratedBox(
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
                if (route != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );

    if (route == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: panel,
      ),
    );
  }
}

class _AboutDetail extends StatelessWidget {
  const _AboutDetail({required this.highlightCommunity});

  final bool highlightCommunity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlightCommunity) ...[
          const _CommunityFocusPanel(),
          const SizedBox(height: 12),
        ],
        const _InfoPanel(
          icon: Icons.shield_outlined,
          title: 'Global Community Intel',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BodyText(
                'HOK Helper brings hero data, build guides, meta trends, and community tools into one mobile-first assistant for Honor of Kings players.',
              ),
              SizedBox(height: 12),
              _BulletText('Cross-region hero intelligence for CN, EN, and ID'),
              _BulletText(
                'Build, draft, tier list, and team composition tools',
              ),
              _BulletText(
                'Community content, patch tracking, and esports context',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _AboutFeatureHighlights(),
      ],
    );
  }
}

class _AboutFeatureHighlights extends StatelessWidget {
  const _AboutFeatureHighlights();

  static const _features = [
    _AboutFeature(
      icon: Icons.bar_chart_outlined,
      title: 'Hero Analytics',
      description: 'Track win, pick, and ban trends for heroes across regions.',
    ),
    _AboutFeature(
      icon: Icons.format_list_bulleted_outlined,
      title: 'Tier Lists',
      description:
          'Community-curated and data-driven tier evaluations updated every patch cycle.',
    ),
    _AboutFeature(
      icon: Icons.sports_martial_arts_outlined,
      title: 'BP Simulator',
      description:
          'Practice your draft strategy with a full pick/ban simulator mirroring the official sequence.',
    ),
    _AboutFeature(
      icon: Icons.bolt_outlined,
      title: 'Build Simulator',
      description:
          'Craft and share optimized equipment builds with community ratings and pro references.',
    ),
    _AboutFeature(
      icon: Icons.auto_fix_high_outlined,
      title: 'AI Prompts',
      description:
          'Generate high-quality skin concept art and hero illustrations with AI-powered prompt tools.',
    ),
    _AboutFeature(
      icon: Icons.groups_2_outlined,
      title: 'Team Builder',
      description:
          'Analyze team compositions and get data-backed recommendations for synergy and counter-picks.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.apps_outlined,
      title: 'What We Offer',
      child: Column(
        children: [
          for (var index = 0; index < _features.length; index++) ...[
            _AboutFeatureTile(feature: _features[index]),
            if (index != _features.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AboutFeature {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _AboutFeatureTile extends StatelessWidget {
  const _AboutFeatureTile({required this.feature});

  final _AboutFeature feature;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: AppTheme.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _BodyText(feature.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityFocusPanel extends StatelessWidget {
  const _CommunityFocusPanel();

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      icon: Icons.groups_2_outlined,
      title: 'Community channel focus',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BodyText(
            'Join discussion, share guides, and keep support links close from the mobile assistant.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/content/community'),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Open Community'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/links'),
                icon: const Icon(Icons.link_outlined),
                label: const Text('Support Links'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqDetail extends StatelessWidget {
  const _FaqDetail();

  @override
  Widget build(BuildContext context) {
    return const _InfoPanel(
      icon: Icons.help_outline,
      title: 'Common questions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionAnswer(
            question: 'Where does hero data come from?',
            answer:
                'Hero, equipment, and stats data are normalized from HOK Helper backend sources and public game-facing datasets for region-aware app views.',
          ),
          SizedBox(height: 12),
          _QuestionAnswer(
            question: 'Can I use it while playing?',
            answer:
                'Use the app as a planning and strategy reference. It does not automate gameplay or replace in-match decision making.',
          ),
          SizedBox(height: 12),
          _QuestionAnswer(
            question: 'Is this an official product?',
            answer:
                'No. HOK Helper is an independent community assistant for learning, discussion, and strategy planning.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyDetail extends StatelessWidget {
  const _PrivacyDetail();

  @override
  Widget build(BuildContext context) {
    return const _InfoPanel(
      icon: Icons.lock_outline,
      title: 'Data use',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText(
            'HOK Helper uses account identifiers, preferences, and interaction data to sync your mobile experience, protect sessions, and improve recommendations.',
          ),
          SizedBox(height: 12),
          _BulletText('JWT sessions are used for authenticated app requests'),
          _BulletText('Region and language preferences shape displayed data'),
          _BulletText(
            'Optional community and prompt actions remain user-driven',
          ),
        ],
      ),
    );
  }
}

class _TermsDetail extends StatelessWidget {
  const _TermsDetail();

  @override
  Widget build(BuildContext context) {
    return const _InfoPanel(
      icon: Icons.description_outlined,
      title: 'Community conduct',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BodyText(
            'Use HOK Helper for lawful strategy research, community discussion, and personal gameplay planning. Shared content should remain respectful and accurate.',
          ),
          SizedBox(height: 12),
          _BulletText('Do not upload abusive, illegal, or misleading content'),
          _BulletText('AI and community tools should support fair play'),
          _BulletText('HOK Helper is independent from the game publisher'),
        ],
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
