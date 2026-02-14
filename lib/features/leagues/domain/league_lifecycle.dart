import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

import 'league.dart';

enum LifecycleStepType {
  fill,
  vetDraft,
  rookieDraft,
  mainDraft,
  schedule,
  regularSeason,
  playoffs,
}

enum StepStatus { completed, current, upcoming }

class LifecycleStep {
  final LifecycleStepType type;
  final String label;
  final StepStatus status;

  const LifecycleStep({
    required this.type,
    required this.label,
    required this.status,
  });
}

class LeagueLifecycleCalculator {
  static List<LifecycleStep> calculateSteps({
    required League league,
    required List<Roster> members,
    required List<Draft> drafts,
    required bool hasSchedule,
  }) {
    final isDynasty = league.mode == 'dynasty' ||
        league.mode == 'keeper' ||
        league.mode == 'devy';

    // Determine completion of each potential step
    final filledCount = members.where((m) => m.userId != null).length;
    final isFilled = filledCount >= league.totalRosters;

    final seasonStatus = league.seasonStatus;
    final pastRegularSeason = seasonStatus == SeasonStatus.regularSeason ||
        seasonStatus == SeasonStatus.playoffs ||
        seasonStatus == SeasonStatus.offseason;
    final pastPlayoffs =
        seasonStatus == SeasonStatus.playoffs ||
        seasonStatus == SeasonStatus.offseason;

    if (isDynasty) {
      return _buildDynastySteps(
        league: league,
        drafts: drafts,
        isFilled: isFilled,
        hasSchedule: hasSchedule,
        pastRegularSeason: pastRegularSeason,
        pastPlayoffs: pastPlayoffs,
      );
    } else {
      return _buildRedraftSteps(
        drafts: drafts,
        isFilled: isFilled,
        hasSchedule: hasSchedule,
        pastRegularSeason: pastRegularSeason,
        pastPlayoffs: pastPlayoffs,
      );
    }
  }

  static List<LifecycleStep> _buildRedraftSteps({
    required List<Draft> drafts,
    required bool isFilled,
    required bool hasSchedule,
    required bool pastRegularSeason,
    required bool pastPlayoffs,
  }) {
    final allDraftsComplete = drafts.isNotEmpty &&
        drafts.every((d) => d.status == DraftStatus.completed);

    final completions = <LifecycleStepType, bool>{
      LifecycleStepType.fill: isFilled,
      LifecycleStepType.mainDraft: allDraftsComplete,
      LifecycleStepType.schedule: hasSchedule,
      LifecycleStepType.regularSeason: pastRegularSeason,
      LifecycleStepType.playoffs: pastPlayoffs,
    };

    final sequence = [
      (LifecycleStepType.fill, 'Fill'),
      (LifecycleStepType.mainDraft, 'Draft'),
      (LifecycleStepType.schedule, 'Schedule'),
      (LifecycleStepType.regularSeason, 'Season'),
      (LifecycleStepType.playoffs, 'Playoffs'),
    ];

    return _assignStatuses(sequence, completions);
  }

  static List<LifecycleStep> _buildDynastySteps({
    required League league,
    required List<Draft> drafts,
    required bool isFilled,
    required bool hasSchedule,
    required bool pastRegularSeason,
    required bool pastPlayoffs,
  }) {
    final vetDrafts = drafts.where((d) => !d.isRookieDraft).toList();
    final rookieDrafts = drafts.where((d) => d.isRookieDraft).toList();

    final vetComplete = vetDrafts.isNotEmpty &&
        vetDrafts.every((d) => d.status == DraftStatus.completed);
    final rookieComplete = rookieDrafts.isNotEmpty &&
        rookieDrafts.every((d) => d.status == DraftStatus.completed);

    // Build sequence — schedule position depends on state
    final sequence = <(LifecycleStepType, String)>[
      (LifecycleStepType.fill, 'Fill'),
      (LifecycleStepType.vetDraft, 'Vet Draft'),
    ];

    // Dynasty schedule positioning heuristic:
    // Schedule exists AND rookie draft not complete → schedule between vet/rookie
    if (hasSchedule && !rookieComplete) {
      sequence.add((LifecycleStepType.schedule, 'Schedule'));
      sequence.add((LifecycleStepType.rookieDraft, 'Rookie'));
    } else {
      sequence.add((LifecycleStepType.rookieDraft, 'Rookie'));
      sequence.add((LifecycleStepType.schedule, 'Schedule'));
    }

    sequence.addAll([
      (LifecycleStepType.regularSeason, 'Season'),
      (LifecycleStepType.playoffs, 'Playoffs'),
    ]);

    final completions = <LifecycleStepType, bool>{
      LifecycleStepType.fill: isFilled,
      LifecycleStepType.vetDraft: vetComplete,
      LifecycleStepType.rookieDraft: rookieComplete,
      LifecycleStepType.schedule: hasSchedule,
      LifecycleStepType.regularSeason: pastRegularSeason,
      LifecycleStepType.playoffs: pastPlayoffs,
    };

    return _assignStatuses(sequence, completions);
  }

  static List<LifecycleStep> _assignStatuses(
    List<(LifecycleStepType, String)> sequence,
    Map<LifecycleStepType, bool> completions,
  ) {
    // Find first incomplete step
    var currentIndex = sequence.indexWhere(
      (entry) => !(completions[entry.$1] ?? false),
    );
    // If all complete, mark last as current
    if (currentIndex == -1) currentIndex = sequence.length - 1;

    return [
      for (var i = 0; i < sequence.length; i++)
        LifecycleStep(
          type: sequence[i].$1,
          label: sequence[i].$2,
          status: i < currentIndex
              ? StepStatus.completed
              : i == currentIndex
                  ? StepStatus.current
                  : StepStatus.upcoming,
        ),
    ];
  }
}
