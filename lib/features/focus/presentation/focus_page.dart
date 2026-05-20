import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../sessions/bloc/stats_bloc.dart';
import '../../sessions/bloc/stats_event.dart';
import '../../tasks/domain/task.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';
import 'pick_task_sheet.dart';
import 'pomodoro_settings_sheet.dart';

import '../../focus_monitoring/bloc/focus_monitoring_bloc.dart';
import '../../focus_monitoring/bloc/focus_monitoring_event.dart';
import '../../focus_monitoring/bloc/focus_monitoring_state.dart';
import '../../focus_monitoring/domain/focus_status.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = context.read<List<CameraDescription>>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => FocusTimerBloc(sessionsRepo: ctx.read()),
        ),
        BlocProvider(
          create: (_) => FocusMonitoringBloc(cameras: cameras),
        ),
      ],
      child: const _FocusView(),
    );
  }
}

class _FocusView extends StatelessWidget {
  const _FocusView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FocusTimerBloc, FocusTimerState>(
          listenWhen: (prev, curr) => prev.sessionSaveNonce != curr.sessionSaveNonce,
          listener: (context, state) {
            context.read<StatsBloc>().add(const StatsRefreshed());
          },
        ),

        // Monitoring lifecycle:
        // - Start when timer is running AND phase is focus
        // - Stop ONLY when leaving focus phase OR when completed
        //   (do NOT stop on pause to avoid disposed-preview race)
        BlocListener<FocusTimerBloc, FocusTimerState>(
          listenWhen: (prev, curr) =>
              prev.isRunning != curr.isRunning ||
              prev.phase != curr.phase ||
              prev.isCompleted != curr.isCompleted,
          listener: (context, timerState) {
            final monitoring = context.read<FocusMonitoringBloc>();

            final shouldStart = timerState.isRunning && timerState.phase == FocusPhase.focus;
            final shouldStop = timerState.phase != FocusPhase.focus || timerState.isCompleted;

            if (shouldStop) {
              monitoring.add(const FocusMonitoringStopped());
              return;
            }

            if (shouldStart) {
              monitoring.add(const FocusMonitoringStarted());
            }
          },
        ),

        // Auto-pause timer when sustained issue detected (only while focus running).
        BlocListener<FocusMonitoringBloc, FocusMonitoringState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, monState) {
            final timerState = context.read<FocusTimerBloc>().state;
            final isInFocusAndRunning =
                timerState.isRunning && timerState.phase == FocusPhase.focus;

            if (!isInFocusAndRunning) return;

            if (monState.status == FocusStatus.absent ||
                monState.status == FocusStatus.distracted ||
                monState.status == FocusStatus.fatigued) {
              context.read<FocusTimerBloc>().add(const FocusTimerPaused());
              // Monitoring keeps running while paused.
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus'),
          actions: [
            IconButton(
              tooltip: 'Pomodoro Settings',
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: BlocBuilder<FocusTimerBloc, FocusTimerState>(
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              _aiActivePill(),
                              const SizedBox(height: 10),
                              _monitoringPill(),
                              const SizedBox(height: 14),
                              _cyclePill(state),
                              const SizedBox(height: 14),
                              _timerRing(state),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: () => _pickTask(context),
                                icon: const Icon(Icons.task_alt, color: AppColors.primary),
                                label: Text(
                                  state.currentTask == null ? 'Choose Task' : 'Change Task',
                                  style: const TextStyle(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _currentTaskCard(state.currentTask),
                              const SizedBox(height: 16),
                              _controls(context, state),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const Positioned(top: 12, right: 12, child: _CameraDebugPreview()),
          ],
        ),
      ),
    );
  }

  Widget _monitoringPill() {
    return BlocBuilder<FocusMonitoringBloc, FocusMonitoringState>(
      builder: (context, s) {
        final color = switch (s.status) {
          FocusStatus.present => AppColors.primary,
          FocusStatus.inactive => AppColors.onSurfaceVariant,
          FocusStatus.absent => AppColors.error,
          FocusStatus.distracted => AppColors.tertiary,
          FocusStatus.fatigued => AppColors.tertiaryContainer,
          FocusStatus.error => AppColors.error,
        };

        final subtitle = s.error != null
            ? 'Error: ${s.error}'
            : 'Active: ${s.focusedActiveSeconds}s / ${s.totalObservedSeconds}s';

        final debug = 'DEBUG: monRunning=${s.isRunning}';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Monitoring: ${s.status.label()}',
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debug,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _aiActivePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.videocam, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text(
            'AI Focus Active',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _cyclePill(FocusTimerState state) {
    final text = state.isCompleted
        ? 'Completed • ${state.totalCycles} cycle(s)'
        : 'Cycle ${state.currentCycle}/${state.totalCycles}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _timerRing(FocusTimerState state) {
    final progress = state.progress01().clamp(0.0, 1.0);
    final timeText = state.isCompleted ? 'Done' : _mmss(state.remainingSeconds);
    final phaseLabel = state.phase.label();

    final ringColor = switch (state.phase) {
      FocusPhase.focus => AppColors.primaryContainer,
      FocusPhase.breakTime => AppColors.tertiaryContainer,
      FocusPhase.completed => AppColors.primary,
    };

    final focusM = (state.focusSeconds ~/ 60);
    final focusS = (state.focusSeconds % 60);
    final breakM = (state.breakSeconds ~/ 60);
    final breakS = (state.breakSeconds % 60);

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: state.isCompleted ? 1 : progress,
              strokeWidth: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(ringColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.phase == FocusPhase.focus
                        ? Icons.bolt
                        : state.phase == FocusPhase.breakTime
                            ? Icons.coffee
                            : Icons.task_alt,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phaseLabel,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${focusM}m ${focusS.toString().padLeft(2, '0')}s focus • '
                '${breakM}m ${breakS.toString().padLeft(2, '0')}s break',
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _currentTaskCard(Task? task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            const Text(
              'Current Task',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task?.title ?? 'No task selected',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, FocusTimerState state) {
    final bloc = context.read<FocusTimerBloc>();

    final startLabel = state.isCompleted ? 'Restart' : (state.isRunning ? 'Pause' : 'Start');
    final startIcon =
        state.isCompleted ? Icons.refresh : (state.isRunning ? Icons.pause : Icons.play_arrow);

    void onStartPressed() {
      if (state.isCompleted) {
        bloc.add(const FocusTimerStopped());
        bloc.add(const FocusTimerStarted());
        return;
      }
      if (state.isRunning) {
        bloc.add(const FocusTimerPaused());
      } else {
        bloc.add(const FocusTimerStarted());
      }
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onStartPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: const Color(0xFF222831),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            icon: Icon(startIcon),
            label: Text(startLabel),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: () => bloc.add(const FocusTimerStopped()),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            foregroundColor: AppColors.onBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.35)),
          ),
          icon: const Icon(Icons.stop),
        ),
      ],
    );
  }

  Future<void> _pickTask(BuildContext context) async {
    final selected = await showModalBottomSheet<Task?>(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      isScrollControlled: true,
      builder: (_) => const PickTaskSheet(),
    );

    if (!context.mounted) return;
    context.read<FocusTimerBloc>().add(FocusTimerTaskSelected(selected));
  }

  Future<void> _openSettings(BuildContext context) async {
    final bloc = context.read<FocusTimerBloc>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const PomodoroSettingsSheet(),
      ),
    );
  }

  static String _mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CameraDebugPreview extends StatelessWidget {
  const _CameraDebugPreview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FocusMonitoringBloc, FocusMonitoringState>(
      builder: (context, s) {
        // IMPORTANT: never build CameraPreview when monitoring is not running.
        if (!s.isRunning) {
          return Container(
            width: 140,
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
            ),
            child: const Center(
              child: Text(
                'Camera: stopped',
                style: TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final controller = s.controller;
        if (controller == null || !controller.value.isInitialized) {
          return Container(
            width: 140,
            height: 190,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
            ),
            child: const Center(
              child: Text(
                'Camera: not ready',
                style: TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final yaw = s.yaw?.toStringAsFixed(1) ?? '-';
        final pitch = s.pitch?.toStringAsFixed(1) ?? '-';
        final eyeL = s.leftEyeOpen?.toStringAsFixed(2) ?? '-';
        final eyeR = s.rightEyeOpen?.toStringAsFixed(2) ?? '-';

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 140,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CameraPreview(controller)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: Colors.black.withOpacity(0.55),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('status=${s.status.label()}'),
                          Text('yaw=$yaw pitch=$pitch'),
                          Text('eyeL=$eyeL eyeR=$eyeR'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}