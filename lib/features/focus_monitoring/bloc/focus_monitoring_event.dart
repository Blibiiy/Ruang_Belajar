import 'package:equatable/equatable.dart';

sealed class FocusMonitoringEvent extends Equatable {
  const FocusMonitoringEvent();
  @override
  List<Object?> get props => [];
}

final class FocusMonitoringStarted extends FocusMonitoringEvent {
  const FocusMonitoringStarted();
}

final class FocusMonitoringStopped extends FocusMonitoringEvent {
  const FocusMonitoringStopped();
}

/// Used internally: tick 1-second evaluation window.
final class FocusMonitoringSecondTicked extends FocusMonitoringEvent {
  const FocusMonitoringSecondTicked();
}