import 'package:bloc/bloc.dart';

import '../../focus_metrics/data/focus_metrics_repository.dart';
import '../../sessions/data/study_session_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

final class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StudySessionRepository repo;
  final FocusMetricsRepository metricsRepo;

  StatsBloc({required this.repo, required this.metricsRepo})
    : super(const StatsState.initial()) {
    on<StatsStarted>(_load);
    on<StatsRefreshed>(_load);
  }

  Future<void> _load(StatsEvent event, Emitter<StatsState> emit) async {
    emit(state.copyWith(status: StatsStatus.loading));
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

      final todaySessions = await repo.getBetween(todayStart, tomorrowStart);
      final last7 = await repo.getBetween(sevenDaysAgo, tomorrowStart);
      final latest = await repo.getLatest(limit: 50);

      final todayFocus = todaySessions.fold<int>(
        0,
        (sum, s) => sum + s.focusSeconds,
      );
      final todayBreak = todaySessions.fold<int>(
        0,
        (sum, s) => sum + s.breakSeconds,
      );
      final completed = todaySessions.where((s) => s.isCompleted).length;

      final ids = latest
          .map((s) => s.id)
          .whereType<int>()
          .toList(growable: false);
      final metricsMap = await metricsRepo.getBySessionIds(ids);

      emit(
        state.copyWith(
          status: StatsStatus.ready,
          todayFocusSeconds: todayFocus,
          todayBreakSeconds: todayBreak,
          todayCompletedSessions: completed,
          last7DaysSessions: last7,
          latestSessions: latest,
          metricsBySessionId: metricsMap,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: StatsStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
