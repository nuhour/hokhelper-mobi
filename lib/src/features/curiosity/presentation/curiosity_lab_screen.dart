import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_section_header.dart';
import '../data/curiosity_repository.dart';
import '../domain/curiosity.dart';

final curiosityRepositoryProvider = Provider<CuriosityRepository>((ref) {
  return CuriosityRepository(apiClient: ref.watch(apiClientProvider));
});

final curiosityOptionsProvider = FutureProvider<CuriosityOptionResult>((ref) {
  return ref
      .watch(curiosityRepositoryProvider)
      .searchOptions(query: '', regionId: 1);
});

class CuriosityLabScreen extends ConsumerStatefulWidget {
  const CuriosityLabScreen({this.initialQuestion, super.key});

  final String? initialQuestion;

  @override
  ConsumerState<CuriosityLabScreen> createState() => _CuriosityLabScreenState();
}

class _CuriosityLabScreenState extends ConsumerState<CuriosityLabScreen> {
  final _questionController = TextEditingController();
  CuriosityAskAnswer? _answer;
  CuriosityCaseResult? _caseResult;
  CuriosityEntity? _source;
  CuriosityEntity? _target;
  String? _verb;
  var _asking = false;
  var _querying = false;
  var _showAdvanced = false;
  var _didAutoAskInitialQuestion = false;

  @override
  void initState() {
    super.initState();
    final initialQuestion = widget.initialQuestion?.trim() ?? '';
    if (initialQuestion.isNotEmpty) {
      _questionController.text = initialQuestion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _askInitialQuestion();
        }
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optionsValue = ref.watch(curiosityOptionsProvider);

    return Material(
      color: Colors.transparent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const _Header(),
          const SizedBox(height: 16),
          _QuestionPanel(
            controller: _questionController,
            asking: _asking,
            onAsk: _ask,
          ),
          const SizedBox(height: 16),
          if (_answer == null)
            const _DashedHint(
              icon: Icons.search_outlined,
              message: 'Ask a mechanics question to start.',
            )
          else
            _AskAnswerCard(answer: _answer!),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(
                _showAdvanced
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
              label: const Text('Advanced Mode'),
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 12),
            AppAsyncView<CuriosityOptionResult>(
              value: optionsValue,
              retry: () => ref.invalidate(curiosityOptionsProvider),
              data: (options) {
                final verbs = options.verbs.isEmpty
                    ? const [
                        CuriosityVerb(
                          key: 'counter',
                          zh: '克制',
                          en: 'counter',
                          id: 'counter',
                        ),
                      ]
                    : options.verbs;
                _verb ??= verbs.first.key;
                return _AdvancedPanel(
                  options: options.rows,
                  verbs: verbs,
                  selectedSource: _source,
                  selectedTarget: _target,
                  selectedVerb: _verb ?? verbs.first.key,
                  querying: _querying,
                  onSourcePicked: (entity) => setState(() => _source = entity),
                  onTargetPicked: (entity) => setState(() => _target = entity),
                  onVerbChanged: (value) => setState(() => _verb = value),
                  onRun: _runExperiment,
                );
              },
            ),
            const SizedBox(height: 16),
            if (_caseResult == null)
              const _DashedHint(
                icon: Icons.science_outlined,
                message: 'Select both sides and run an experiment.',
              )
            else
              _CaseResultCard(result: _caseResult!),
          ],
        ],
      ),
    );
  }

  Future<void> _ask() async {
    final query = _questionController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() => _asking = true);
    try {
      final result = await ref
          .read(curiosityRepositoryProvider)
          .askQuestion(query: query, regionId: 1, lang: 'en');
      setState(() => _answer = result);
    } finally {
      if (mounted) {
        setState(() => _asking = false);
      }
    }
  }

  void _askInitialQuestion() {
    if (_didAutoAskInitialQuestion) {
      return;
    }
    _didAutoAskInitialQuestion = true;
    _ask();
  }

  Future<void> _runExperiment() async {
    final source = _source;
    final target = _target;
    final verb = _verb;
    if (source == null || target == null || verb == null) {
      return;
    }

    setState(() => _querying = true);
    try {
      final result = await ref
          .read(curiosityRepositoryProvider)
          .queryCase(source: source, target: target, verb: verb, regionId: 1);
      setState(() => _caseResult = result);
    } finally {
      if (mounted) {
        setState(() => _querying = false);
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Curiosity Lab'),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.12),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'HOK Curiosity Lab',
              style: TextStyle(
                color: AppTheme.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Build interaction questions and query experiment results with replay evidence.',
          style: TextStyle(color: AppTheme.muted, height: 1.4),
        ),
      ],
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.controller,
    required this.asking,
    required this.onAsk,
  });

  final TextEditingController controller;
  final bool asking;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onAsk(),
                decoration: const InputDecoration(
                  hintText: 'Can Kongming dash through walls?',
                  prefixIcon: Icon(Icons.search_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: asking ? null : onAsk,
              child: Text(asking ? 'Asking...' : 'Ask'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskAnswerCard extends StatelessWidget {
  const _AskAnswerCard({required this.answer});

  final CuriosityAskAnswer answer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SmallLabel('Conclusion'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _resultIcon(answer.result),
                  color: _resultColor(answer.result),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    answer.resultLabel.en.isEmpty
                        ? answer.result
                        : answer.resultLabel.en,
                    style: TextStyle(
                      color: _resultColor(answer.result),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ConfidenceChip(
                  score: answer.confidenceScore,
                  level: answer.confidenceLevel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(answer.answer, style: const TextStyle(color: AppTheme.text)),
            if (answer.conditions.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SmallLabel('Conditions'),
              const SizedBox(height: 8),
              ...answer.conditions.map(
                (condition) => _InfoLine(text: condition.text),
              ),
            ],
            const SizedBox(height: 14),
            const _SmallLabel('Evidence'),
            const SizedBox(height: 8),
            if (answer.evidence.isEmpty)
              const _InfoLine(text: 'No evidence yet.')
            else
              ...answer.evidence.map(
                (evidence) => _EvidenceLine(evidence: evidence),
              ),
            if (answer.allowSubmission) ...[
              const SizedBox(height: 14),
              const Text(
                'Submit Correction Video',
                style: TextStyle(
                  color: AppTheme.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdvancedPanel extends StatelessWidget {
  const _AdvancedPanel({
    required this.options,
    required this.verbs,
    required this.selectedSource,
    required this.selectedTarget,
    required this.selectedVerb,
    required this.querying,
    required this.onSourcePicked,
    required this.onTargetPicked,
    required this.onVerbChanged,
    required this.onRun,
  });

  final List<CuriosityEntity> options;
  final List<CuriosityVerb> verbs;
  final CuriosityEntity? selectedSource;
  final CuriosityEntity? selectedTarget;
  final String selectedVerb;
  final bool querying;
  final ValueChanged<CuriosityEntity> onSourcePicked;
  final ValueChanged<CuriosityEntity> onTargetPicked;
  final ValueChanged<String> onVerbChanged;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SmallLabel('Source'),
            const SizedBox(height: 8),
            _EntityWrap(
              options: options,
              selected: selectedSource,
              onPicked: onSourcePicked,
            ),
            const SizedBox(height: 14),
            const _SmallLabel('Relation'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedVerb,
              items: verbs
                  .map(
                    (verb) => DropdownMenuItem(
                      value: verb.key,
                      child: Text(verb.en.isEmpty ? verb.key : verb.en),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onVerbChanged(value);
              },
            ),
            const SizedBox(height: 14),
            const _SmallLabel('Target'),
            const SizedBox(height: 8),
            _EntityWrap(
              options: options,
              selected: selectedTarget,
              onPicked: onTargetPicked,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: querying ? null : onRun,
                icon: const Icon(Icons.science_outlined),
                label: Text(querying ? 'Querying...' : 'Run Experiment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityWrap extends StatelessWidget {
  const _EntityWrap({
    required this.options,
    required this.selected,
    required this.onPicked,
  });

  final List<CuriosityEntity> options;
  final CuriosityEntity? selected;
  final ValueChanged<CuriosityEntity> onPicked;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const AppEmptyState(
        icon: Icons.category_outlined,
        title: 'No options',
        message: 'No experiment entities are available yet.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((entity) {
        final active = selected?.key == entity.key;
        return ChoiceChip(
          selected: active,
          label: Text(entity.name),
          onSelected: (_) => onPicked(entity),
        );
      }).toList(),
    );
  }
}

class _CaseResultCard extends StatelessWidget {
  const _CaseResultCard({required this.result});

  final CuriosityCaseResult result;

  @override
  Widget build(BuildContext context) {
    final primaryVideos = result.videos.where((video) => video.isPrimary);
    final primaryVideo = primaryVideos.isNotEmpty
        ? primaryVideos.first
        : (result.videos.isEmpty ? null : result.videos.first);
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _resultIcon(result.result),
                  color: _resultColor(result.result),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.resultLabel.en.isEmpty
                        ? result.result
                        : result.resultLabel.en,
                    style: TextStyle(
                      color: _resultColor(result.result),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ConfidenceChip(score: result.confidenceScore, level: 'case'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.reasoning,
              style: const TextStyle(color: AppTheme.text),
            ),
            const SizedBox(height: 14),
            const _SmallLabel('Reproduction Videos'),
            const SizedBox(height: 8),
            if (primaryVideo == null)
              const _InfoLine(text: 'No videos yet.')
            else
              _VideoLine(video: primaryVideo),
            if (result.videos.length > 1)
              ...result.videos.skip(1).map((video) => _VideoLine(video: video)),
            if (result.allowSubmission) ...[
              const SizedBox(height: 14),
              const Text(
                'Submit Correction Video',
                style: TextStyle(
                  color: AppTheme.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedHint extends StatelessWidget {
  const _DashedHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.52),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.muted, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.score, required this.level});

  final int score;
  final String level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$level $score',
          style: const TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.muted,
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(text, style: const TextStyle(color: AppTheme.text)),
        ),
      ),
    );
  }
}

class _EvidenceLine extends StatelessWidget {
  const _EvidenceLine({required this.evidence});

  final CuriosityEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evidence.title,
                style: const TextStyle(color: AppTheme.text),
              ),
              if (evidence.sourceLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  evidence.sourceLabel,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoLine extends StatelessWidget {
  const _VideoLine({required this.video});

  final CuriosityVideo video;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((video.note ?? '').isNotEmpty)
                Text(video.note!, style: const TextStyle(color: AppTheme.text)),
              if ((video.experimenterName ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Experimenter: ${video.experimenterName}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
              if (video.videoUrl.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  video.videoUrl,
                  style: const TextStyle(color: AppTheme.cyan, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.panel,
    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    borderRadius: BorderRadius.circular(16),
  );
}

IconData _resultIcon(String result) {
  return switch (result) {
    'yes' => Icons.check_circle_outline,
    'no' => Icons.cancel_outlined,
    'conditional' => Icons.help_outline,
    'partial' => Icons.rule_outlined,
    _ => Icons.help_outline,
  };
}

Color _resultColor(String result) {
  return switch (result) {
    'yes' => const Color(0xFF34D399),
    'no' => AppTheme.error,
    'conditional' => AppTheme.gold,
    'partial' => AppTheme.cyan,
    _ => AppTheme.muted,
  };
}
