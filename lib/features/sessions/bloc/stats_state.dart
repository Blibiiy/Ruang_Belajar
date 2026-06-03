import 'package:equatable/equatable.dart';
import '../../focus_metrics/domain/focus_session_metrics.dart';
import '../domain/study_session.dart';

enum StatsStatus { initial, loading, ready, failure }

final class StatsState extends Equatable {
  final StatsStatus status;

  final int todayFocusSeconds;
  final int todayBreakSeconds;
  final int todayCompletedSessions;

  /// sessions in last 7 days range
  final List<StudySession> last7DaysSessions;

  /// latest sessions for history list
  final List<StudySession> latestSessions;

  /// NEW: metrics keyed by session id
  final Map<int, FocusSessionMetrics> metricsBySessionId;

  final String? errorMessage;

  const StatsState({
    required this.status,
    required this.todayFocusSeconds,
    required this.todayBreakSeconds,
    required this.todayCompletedSessions,
    required this.last7DaysSessions,
    required this.latestSessions,
    required this.metricsBySessionId,
    this.errorMessage,
  });

  const StatsState.initial()
      : status = StatsStatus.initial,
        todayFocusSeconds = 0,
        todayBreakSeconds = 0,
        todayCompletedSessions = 0,
        last7DaysSessions = const [],
        latestSessions = const [],
        metricsBySessionId = const {},
        errorMessage = null;

  StatsState copyWith({
    StatsStatus? status,
    int? todayFocusSeconds,
    int? todayBreakSeconds,
    int? todayCompletedSessions,
    List<StudySession>? last7DaysSessions,
    List<StudySession>? latestSessions,
    Map<int, FocusSessionMetrics>? metricsBySessionId,
    String? errorMessage,
  }) {
    return StatsState(
      status: status ?? this.status,
      todayFocusSeconds: todayFocusSeconds ?? this.todayFocusSeconds,
      todayBreakSeconds: todayBreakSeconds ?? this.todayBreakSeconds,
      todayCompletedSessions: todayCompletedSessions ?? this.todayCompletedSessions,
      last7DaysSessions: last7DaysSessions ?? this.last7DaysSessions,
      latestSessions: latestSessions ?? this.latestSessions,
      metricsBySessionId: metricsBySessionId ?? this.metricsBySessionId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todayFocusSeconds,
        todayBreakSeconds,
        todayCompletedSessions,
        last7DaysSessions,
        latestSessions,
        metricsBySessionId,
        errorMessage,
      ];
}