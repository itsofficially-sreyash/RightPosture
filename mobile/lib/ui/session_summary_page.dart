import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../session_controller.dart';
import 'app_theme.dart';

class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    return SessionSummaryView(
      state: state,
      onRestart: ref.read(sessionControllerProvider.notifier).reset,
    );
  }
}

class SessionSummaryView extends StatelessWidget {
  const SessionSummaryView({
    super.key,
    required this.state,
    required this.onRestart,
  });

  final SessionState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final degraded = summary?.degradationStartRep != null;
    final score = summary?.formScorePercent;
    return Scaffold(
      backgroundColor: AppColors.lime,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: AppSpacing.medium),
                      Semantics(
                        header: true,
                        child: Text(
                          degraded ? 'Set reviewed' : 'Set complete',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: AppColors.background),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Semantics(
                        label: score == null
                            ? 'Form score unavailable. Not enough data.'
                            : 'Form score ${score.round()} percent',
                        child: ExcludeSemantics(
                          child: Text(
                            score == null
                                ? 'Not enough data'
                                : '${score.round()}%',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(color: AppColors.background),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        '${summary?.totalReps ?? 0} total reps',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (degraded) ...[
                        const SizedBox(height: AppSpacing.medium),
                        _SummaryCallout(summary: summary!),
                      ],
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        'Rep checklist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      if (state.reps.isEmpty)
                        const _EmptyChecklist()
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            child: Column(
                              children: [
                                for (final rep in state.reps) _RepRow(rep: rep),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.extraLarge),
                      FilledButton(
                        key: const Key('restart_session'),
                        onPressed: onRestart,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.lime,
                        ),
                        child: const Text('Restart'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCallout extends StatelessWidget {
  const _SummaryCallout({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insights, color: AppColors.warning),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                'Form degradation detected from rep '
                '${summary.degradationStartRep}. '
                'Primary movement change: '
                '${summary.primaryResponsibleJoint ?? 'unknown joint'}.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepRow extends StatelessWidget {
  const _RepRow({required this.rep});

  final Rep rep;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (rep.status) {
      RepStatus.calibrating => (Icons.tune, AppColors.textMuted, 'calibrating'),
      RepStatus.good => (Icons.check_circle, AppColors.lime, 'good'),
      RepStatus.warning => (Icons.warning_amber, AppColors.warning, 'warning'),
      RepStatus.degraded => (Icons.cancel, AppColors.degraded, 'degraded'),
    };
    return Semantics(
      label:
          'Rep ${rep.number}, $label${rep.reason == null ? '' : ', ${rep.reason}'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: Text('Rep ${rep.number} · $label')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Text('Complete at least one rep to see feedback.'),
      ),
    );
  }
}
