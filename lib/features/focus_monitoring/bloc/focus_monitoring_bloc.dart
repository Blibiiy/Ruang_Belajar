import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../domain/focus_status.dart';
import '../mlkit/camera_image_converter.dart';
import 'focus_monitoring_event.dart';
import 'focus_monitoring_state.dart';

final class FocusMonitoringBloc extends Bloc<FocusMonitoringEvent, FocusMonitoringState> {
  final List<CameraDescription> cameras;

  FocusMonitoringBloc({required this.cameras}) : super(const FocusMonitoringState.initial()) {
    on<FocusMonitoringStarted>(_onStart);
    on<FocusMonitoringStopped>(_onStop);
    on<FocusMonitoringSecondTicked>(_onSecondTick);
  }

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: true,
      enableTracking: false,
      minFaceSize: 0.15,
    ),
  );

  bool _processingFrame = false;
  Face? _latestFace;

  Timer? _tickTimer;

  static const int toleranceSeconds = 3;

  int _absentStreak = 0;
  int _distractedStreak = 0;
  int _fatiguedStreak = 0;

  static const double yawThreshold = 15.0;
  static const double pitchThreshold = 15.0;
  static const double eyeOpenThreshold = 0.5;

  Future<void> _onStart(FocusMonitoringStarted e, Emitter<FocusMonitoringState> emit) async {
    if (state.isRunning) return;

    try {
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      await controller.startImageStream((CameraImage image) async {
        if (_processingFrame) return;
        _processingFrame = true;
        try {
          final rotation = front.sensorOrientation;

          final input = CameraImageConverter.toInputImage(
            image,
            camera: front,
            rotationDegrees: rotation,
          );

          if (input == null) {
            _latestFace = null;
            return;
          }

          final faces = await _detector.processImage(input);
          _latestFace = faces.isNotEmpty ? faces.first : null;
        } catch (_) {
          // ignore per-frame errors
        } finally {
          _processingFrame = false;
        }
      });

      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(const FocusMonitoringSecondTicked());
      });

      _latestFace = null;
      _absentStreak = 0;
      _distractedStreak = 0;
      _fatiguedStreak = 0;

      emit(
        state.copyWith(
          isRunning: true,
          // IMPORTANT: start as inactive. We will set present/absent/etc after first tick.
          status: FocusStatus.inactive,
          controller: controller,
          clearError: true,
          focusedActiveSeconds: 0,
          totalObservedSeconds: 0,
          absentSeconds: 0,
          distractedSeconds: 0,
          fatiguedSeconds: 0,
          absentEvents: 0,
          distractedEvents: 0,
          fatiguedEvents: 0,
        ),
      );
    } catch (err) {
      emit(state.copyWith(
        isRunning: false,
        status: FocusStatus.error,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onStop(FocusMonitoringStopped e, Emitter<FocusMonitoringState> emit) async {
    _tickTimer?.cancel();
    _tickTimer = null;

    final controller = state.controller;
    if (controller != null) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
      try {
        await controller.dispose();
      } catch (_) {}
    }

    _latestFace = null;
    _processingFrame = false;
    _absentStreak = 0;
    _distractedStreak = 0;
    _fatiguedStreak = 0;

    emit(state.copyWith(
      isRunning: false,
      status: FocusStatus.inactive,
      controller: null,
    ));
  }

  void _onSecondTick(FocusMonitoringSecondTicked e, Emitter<FocusMonitoringState> emit) {
    if (!state.isRunning) return;

    final face = _latestFace;
    final totalObservedSeconds = state.totalObservedSeconds + 1;

    FocusStatus inst;
    double? yaw, pitch, roll, leftEye, rightEye;

    if (face == null) {
      inst = FocusStatus.absent;
    } else {
      yaw = face.headEulerAngleY;
      pitch = face.headEulerAngleX;
      roll = face.headEulerAngleZ;
      leftEye = face.leftEyeOpenProbability;
      rightEye = face.rightEyeOpenProbability;

      final isDistracted = (yaw != null && yaw.abs() > yawThreshold) ||
          (pitch != null && pitch.abs() > pitchThreshold);

      final avgEye = (leftEye != null && rightEye != null) ? (leftEye + rightEye) / 2.0 : null;
      final isFatigued = (avgEye != null && avgEye < eyeOpenThreshold);

      if (isDistracted) {
        inst = FocusStatus.distracted;
      } else if (isFatigued) {
        inst = FocusStatus.fatigued;
      } else {
        inst = FocusStatus.present;
      }
    }

    _absentStreak = (inst == FocusStatus.absent) ? _absentStreak + 1 : 0;
    _distractedStreak = (inst == FocusStatus.distracted) ? _distractedStreak + 1 : 0;
    _fatiguedStreak = (inst == FocusStatus.fatigued) ? _fatiguedStreak + 1 : 0;

    FocusStatus stable = FocusStatus.present;
    var absentEvents = state.absentEvents;
    var distractedEvents = state.distractedEvents;
    var fatiguedEvents = state.fatiguedEvents;

    if (_absentStreak >= toleranceSeconds) {
      stable = FocusStatus.absent;
      if (state.status != FocusStatus.absent) absentEvents += 1;
    } else if (_distractedStreak >= toleranceSeconds) {
      stable = FocusStatus.distracted;
      if (state.status != FocusStatus.distracted) distractedEvents += 1;
    } else if (_fatiguedStreak >= toleranceSeconds) {
      stable = FocusStatus.fatigued;
      if (state.status != FocusStatus.fatigued) fatiguedEvents += 1;
    } else {
      stable = FocusStatus.present;
    }

    final absentSeconds = state.absentSeconds + (inst == FocusStatus.absent ? 1 : 0);
    final distractedSeconds = state.distractedSeconds + (inst == FocusStatus.distracted ? 1 : 0);
    final fatiguedSeconds = state.fatiguedSeconds + (inst == FocusStatus.fatigued ? 1 : 0);

    final focusedActiveSeconds =
        state.focusedActiveSeconds + (inst == FocusStatus.present ? 1 : 0);

    emit(state.copyWith(
      status: stable,
      totalObservedSeconds: totalObservedSeconds,
      focusedActiveSeconds: focusedActiveSeconds,
      absentSeconds: absentSeconds,
      distractedSeconds: distractedSeconds,
      fatiguedSeconds: fatiguedSeconds,
      absentEvents: absentEvents,
      distractedEvents: distractedEvents,
      fatiguedEvents: fatiguedEvents,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      leftEyeOpen: leftEye,
      rightEyeOpen: rightEye,
    ));
  }

  @override
  Future<void> close() async {
    _tickTimer?.cancel();
    try {
      await _detector.close();
    } catch (_) {}

    final controller = state.controller;
    if (controller != null) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
      try {
        await controller.dispose();
      } catch (_) {}
    }
    return super.close();
  }
}