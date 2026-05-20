import 'package:bloc/bloc.dart';
import '../../sessions/data/study_session_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

final class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final StudySessionRepository repo;

  StatsBloc({required this.repo}) : super(const StatsState.initial()) {
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

      final todayFocus = todaySessions.fold<int>(0, (sum, s) => sum + s.focusSeconds);
      final todayBreak = todaySessions.fold<int>(0, (sum, s) => sum + s.breakSeconds);
      final completed = todaySessions.where((s) => s.isCompleted).length;

      emit(
        state.copyWith(
          status: StatsStatus.ready,
          todayFocusSeconds: todayFocus,
          todayBreakSeconds: todayBreak,
          todayCompletedSessions: completed,
          last7DaysSessions: last7,
          latestSessions: latest,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: StatsStatus.failure, errorMessage: e.toString()));
    }
  }
}