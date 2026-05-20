import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

import '../domain/focus_status.dart';

final class FocusMonitoringState extends Equatable {
  final bool isRunning;
  final FocusStatus status;

  final CameraController? controller;
  final String? error;

  // rolling counters (seconds)
  final int focusedActiveSeconds; // present & not distracted & not absent
  final int totalObservedSeconds; // while monitoring running

  final int absentSeconds;
  final int distractedSeconds;
  final int fatiguedSeconds;

  // event counters (when condition becomes "stable" after tolerance)
  final int absentEvents;
  final int distractedEvents;
  final int fatiguedEvents;

  // last face properties (debug)
  final double? yaw;
  final double? pitch;
  final double? roll;
  final double? leftEyeOpen;
  final double? rightEyeOpen;

  const FocusMonitoringState({
    required this.isRunning,
    required this.status,
    required this.controller,
    required this.error,
    required this.focusedActiveSeconds,
    required this.totalObservedSeconds,
    required this.absentSeconds,
    required this.distractedSeconds,
    required this.fatiguedSeconds,
    required this.absentEvents,
    required this.distractedEvents,
    required this.fatiguedEvents,
    this.yaw,
    this.pitch,
    this.roll,
    this.leftEyeOpen,
    this.rightEyeOpen,
  });

  const FocusMonitoringState.initial()
      : isRunning = false,
        status = FocusStatus.inactive,
        controller = null,
        error = null,
        focusedActiveSeconds = 0,
        totalObservedSeconds = 0,
        absentSeconds = 0,
        distractedSeconds = 0,
        fatiguedSeconds = 0,
        absentEvents = 0,
        distractedEvents = 0,
        fatiguedEvents = 0,
        yaw = null,
        pitch = null,
        roll = null,
        leftEyeOpen = null,
        rightEyeOpen = null;

  FocusMonitoringState copyWith({
    bool? isRunning,
    FocusStatus? status,
    CameraController? controller,
    String? error,
    int? focusedActiveSeconds,
    int? totalObservedSeconds,
    int? absentSeconds,
    int? distractedSeconds,
    int? fatiguedSeconds,
    int? absentEvents,
    int? distractedEvents,
    int? fatiguedEvents,
    double? yaw,
    double? pitch,
    double? roll,
    double? leftEyeOpen,
    double? rightEyeOpen,
    bool clearError = false,
  }) {
    return FocusMonitoringState(
      isRunning: isRunning ?? this.isRunning,
      status: status ?? this.status,
      controller: controller ?? this.controller,
      error: clearError ? null : (error ?? this.error),
      focusedActiveSeconds: focusedActiveSeconds ?? this.focusedActiveSeconds,
      totalObservedSeconds: totalObservedSeconds ?? this.totalObservedSeconds,
      absentSeconds: absentSeconds ?? this.absentSeconds,
      distractedSeconds: distractedSeconds ?? this.distractedSeconds,
      fatiguedSeconds: fatiguedSeconds ?? this.fatiguedSeconds,
      absentEvents: absentEvents ?? this.absentEvents,
      distractedEvents: distractedEvents ?? this.distractedEvents,
      fatiguedEvents: fatiguedEvents ?? this.fatiguedEvents,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      leftEyeOpen: leftEyeOpen ?? this.leftEyeOpen,
      rightEyeOpen: rightEyeOpen ?? this.rightEyeOpen,
    );
  }

  @override
  List<Object?> get props => [
        isRunning,
        status,
        controller,
        error,
        focusedActiveSeconds,
        totalObservedSeconds,
        absentSeconds,
        distractedSeconds,
        fatiguedSeconds,
        absentEvents,
        distractedEvents,
        fatiguedEvents,
        yaw,
        pitch,
        roll,
        leftEyeOpen,
        rightEyeOpen,
      ];
}