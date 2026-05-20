import 'package:equatable/equatable.dart';
import '../../tasks/domain/task.dart';

sealed class FocusTimerEvent extends Equatable {
  const FocusTimerEvent();
  @override
  List<Object?> get props => [];
}

final class FocusTimerStarted extends FocusTimerEvent {
  const FocusTimerStarted();
}

final class FocusTimerPaused extends FocusTimerEvent {
  const FocusTimerPaused();
}

final class FocusTimerStopped extends FocusTimerEvent {
  const FocusTimerStopped();
}

final class FocusTimerTicked extends FocusTimerEvent {
  const FocusTimerTicked();
}

final class FocusTimerTaskSelected extends FocusTimerEvent {
  final Task? task;
  const FocusTimerTaskSelected(this.task);

  @override
  List<Object?> get props => [task];
}

final class FocusTimerSettingsUpdated extends FocusTimerEvent {
  final int focusMinutes;
  final int focusSeconds;
  final int breakMinutes;
  final int breakSeconds;
  final int cycles;

  const FocusTimerSettingsUpdated({
    required this.focusMinutes,
    required this.focusSeconds,
    required this.breakMinutes,
    required this.breakSeconds,
    required this.cycles,
  });

  @override
  List<Object?> get props => [focusMinutes, focusSeconds, breakMinutes, breakSeconds, cycles];
}