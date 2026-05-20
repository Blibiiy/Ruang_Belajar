import 'package:equatable/equatable.dart';

final class StudySession extends Equatable {
  final int? id;
  final int? taskId;

  final DateTime startedAt;
  final DateTime endedAt;

  final int focusSeconds;
  final int breakSeconds;

  final int plannedCycles;
  final int completedCycles;

  final bool isCompleted;
  final DateTime createdAt;

  const StudySession({
    this.id,
    this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.focusSeconds,
    required this.breakSeconds,
    required this.plannedCycles,
    required this.completedCycles,
    required this.isCompleted,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        taskId,
        startedAt,
        endedAt,
        focusSeconds,
        breakSeconds,
        plannedCycles,
        completedCycles,
        isCompleted,
        createdAt,
      ];
}