final class FocusSessionMetrics {
  final int sessionId;

  final int focusTotalSeconds;
  final int focusActiveSeconds;

  final int absentSeconds;
  final int distractedSeconds;
  final int fatiguedSeconds;

  final int absentEvents;
  final int distractedEvents;
  final int fatiguedEvents;

  /// 0..100
  final double focusScore;

  final DateTime createdAt;

  const FocusSessionMetrics({
    required this.sessionId,
    required this.focusTotalSeconds,
    required this.focusActiveSeconds,
    required this.absentSeconds,
    required this.distractedSeconds,
    required this.fatiguedSeconds,
    required this.absentEvents,
    required this.distractedEvents,
    required this.fatiguedEvents,
    required this.focusScore,
    required this.createdAt,
  });
}