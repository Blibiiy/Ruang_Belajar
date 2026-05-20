import 'package:equatable/equatable.dart';
import '../../tasks/domain/task.dart';

enum FocusPhase { focus, breakTime, completed }

extension FocusPhaseX on FocusPhase {
  String label() => switch (this) {
        FocusPhase.focus => 'Deep Work',
        FocusPhase.breakTime => 'Break',
        FocusPhase.completed => 'Complete',
      };
}

final class FocusTimerState extends Equatable {
  final FocusPhase phase;
  final bool isRunning;

  final int remainingSeconds;

  final int focusSeconds;
  final int breakSeconds;

  final int totalCycles;
  final int currentCycle;

  final Task? currentTask;

  /// Increments whenever a StudySession is saved to DB.
  final int sessionSaveNonce;

  const FocusTimerState({
    required this.phase,
    required this.isRunning,
    required this.remainingSeconds,
    required this.focusSeconds,
    required this.breakSeconds,
    required this.totalCycles,
    required this.currentCycle,
    required this.currentTask,
    required this.sessionSaveNonce,
  });

  factory FocusTimerState.initial() => const FocusTimerState(
        phase: FocusPhase.focus,
        isRunning: false,
        focusSeconds: 25 * 60,
        breakSeconds: 5 * 60,
        totalCycles: 1,
        currentCycle: 1,
        remainingSeconds: 25 * 60,
        currentTask: null,
        sessionSaveNonce: 0,
      );

  FocusTimerState copyWith({
    FocusPhase? phase,
    bool? isRunning,
    int? remainingSeconds,
    int? focusSeconds,
    int? breakSeconds,
    int? totalCycles,
    int? currentCycle,
    Task? currentTask,
    bool clearTask = false,
    int? sessionSaveNonce,
  }) {
    return FocusTimerState(
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      focusSeconds: focusSeconds ?? this.focusSeconds,
      breakSeconds: breakSeconds ?? this.breakSeconds,
      totalCycles: totalCycles ?? this.totalCycles,
      currentCycle: currentCycle ?? this.currentCycle,
      currentTask: clearTask ? null : (currentTask ?? this.currentTask),
      sessionSaveNonce: sessionSaveNonce ?? this.sessionSaveNonce,
    );
  }

  double progress01() {
    final total = switch (phase) {
      FocusPhase.focus => focusSeconds,
      FocusPhase.breakTime => breakSeconds,
      FocusPhase.completed => 1,
    };
    if (total <= 0) return 0;
    return remainingSeconds / total;
  }

  bool get isCompleted => phase == FocusPhase.completed;

  @override
  List<Object?> get props => [
        phase,
        isRunning,
        remainingSeconds,
        focusSeconds,
        breakSeconds,
        totalCycles,
        currentCycle,
        currentTask,
        sessionSaveNonce,
      ];
}