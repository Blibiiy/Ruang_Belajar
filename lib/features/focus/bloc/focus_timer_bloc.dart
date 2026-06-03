import 'dart:async';
import 'package:bloc/bloc.dart';

import '../../sessions/data/study_session_repository.dart';
import '../../sessions/domain/study_session.dart';
import 'focus_timer_event.dart';
import 'focus_timer_state.dart';

final class FocusTimerBloc extends Bloc<FocusTimerEvent, FocusTimerState> {
  final StudySessionRepository sessionsRepo;

  Timer? _timer;

  DateTime? _sessionStartedAt;
  int _spentFocusSeconds = 0;
  int _spentBreakSeconds = 0;
  int _completedCycles = 0;

  static const int _minFocusSecondsToLogOnStop = 60; // 1 minute

  FocusTimerBloc({required this.sessionsRepo}) : super(FocusTimerState.initial()) {
    on<FocusTimerStarted>(_onStart);
    on<FocusTimerPaused>(_onPause);
    on<FocusTimerStopped>(_onStop);
    on<FocusTimerTicked>(_onTick);
    on<FocusTimerTaskSelected>(_onSelectTask);
    on<FocusTimerSettingsUpdated>(_onSettingsUpdated);
  }

  void _resetSessionTracking() {
    _sessionStartedAt = null;
    _spentFocusSeconds = 0;
    _spentBreakSeconds = 0;
    _completedCycles = 0;
  }

  Future<void> _persistSession({required bool isCompleted}) async {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) return;

    final endedAt = DateTime.now();
    final session = StudySession(
      taskId: state.currentTask?.id,
      startedAt: startedAt,
      endedAt: endedAt,
      focusSeconds: _spentFocusSeconds,
      breakSeconds: _spentBreakSeconds,
      plannedCycles: state.totalCycles,
      completedCycles: _completedCycles,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
    );

    final saved = await sessionsRepo.insert(session);

    emit(state.copyWith(
      sessionSaveNonce: state.sessionSaveNonce + 1,
      lastSavedSession: saved,
    ));
  }

  void _onSelectTask(FocusTimerTaskSelected e, Emitter<FocusTimerState> emit) {
    emit(state.copyWith(currentTask: e.task, clearTask: e.task == null));
  }

  void _onSettingsUpdated(FocusTimerSettingsUpdated e, Emitter<FocusTimerState> emit) {
    final focusMin = e.focusMinutes.clamp(0, 180);
    final focusSecExtra = e.focusSeconds.clamp(0, 59);
    final breakMin = e.breakMinutes.clamp(0, 60);
    final breakSecExtra = e.breakSeconds.clamp(0, 59);
    final cycles = e.cycles.clamp(1, 12);

    final focusSec = (focusMin * 60) + focusSecExtra;
    final breakSec = (breakMin * 60) + breakSecExtra;

    final safeFocus = focusSec <= 0 ? 1 : focusSec;

    _timer?.cancel();
    _timer = null;

    _resetSessionTracking();

    emit(
      state.copyWith(
        isRunning: false,
        phase: FocusPhase.focus,
        focusSeconds: safeFocus,
        breakSeconds: breakSec,
        totalCycles: cycles,
        currentCycle: 1,
        remainingSeconds: safeFocus,
      ),
    );
  }

  void _onStart(FocusTimerStarted e, Emitter<FocusTimerState> emit) {
    if (state.isRunning) return;

    _sessionStartedAt ??= DateTime.now();

    if (state.phase == FocusPhase.completed) {
      _resetSessionTracking();
      _sessionStartedAt = DateTime.now();

      emit(
        state.copyWith(
          phase: FocusPhase.focus,
          currentCycle: 1,
          remainingSeconds: state.focusSeconds,
          isRunning: true,
        ),
      );
    } else {
      emit(state.copyWith(isRunning: true));
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const FocusTimerTicked());
    });
  }

  void _onPause(FocusTimerPaused e, Emitter<FocusTimerState> emit) {
    _timer?.cancel();
    _timer = null;
    emit(state.copyWith(isRunning: false));
  }

  Future<void> _onStop(FocusTimerStopped e, Emitter<FocusTimerState> emit) async {
    _timer?.cancel();
    _timer = null;

    if (_spentFocusSeconds >= _minFocusSecondsToLogOnStop) {
      await _persistSession(isCompleted: false);
    }

    _resetSessionTracking();

    emit(
      state.copyWith(
        isRunning: false,
        phase: FocusPhase.focus,
        currentCycle: 1,
        remainingSeconds: state.focusSeconds,
      ),
    );
  }

  Future<void> _onTick(FocusTimerTicked e, Emitter<FocusTimerState> emit) async {
    if (!state.isRunning) return;
    if (state.phase == FocusPhase.completed) return;

    if (state.phase == FocusPhase.focus) {
      _spentFocusSeconds += 1;
    } else if (state.phase == FocusPhase.breakTime) {
      _spentBreakSeconds += 1;
    }

    final next = state.remainingSeconds - 1;

    if (next > 0) {
      emit(state.copyWith(remainingSeconds: next));
      return;
    }

    if (state.phase == FocusPhase.focus) {
      _completedCycles = state.currentCycle;

      if (state.currentCycle >= state.totalCycles) {
        _timer?.cancel();
        _timer = null;

        await _persistSession(isCompleted: true);
        _resetSessionTracking();

        emit(state.copyWith(
          isRunning: false,
          phase: FocusPhase.completed,
          remainingSeconds: 0,
        ));
        return;
      }

      if (state.breakSeconds <= 0) {
        emit(state.copyWith(
          phase: FocusPhase.focus,
          currentCycle: state.currentCycle + 1,
          remainingSeconds: state.focusSeconds,
        ));
        return;
      }

      emit(state.copyWith(
        phase: FocusPhase.breakTime,
        remainingSeconds: state.breakSeconds,
      ));
      return;
    }

    if (state.phase == FocusPhase.breakTime) {
      emit(state.copyWith(
        phase: FocusPhase.focus,
        currentCycle: state.currentCycle + 1,
        remainingSeconds: state.focusSeconds,
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}