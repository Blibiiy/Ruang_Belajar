import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  int toDb() => switch (this) {
        TaskPriority.low => 0,
        TaskPriority.medium => 1,
        TaskPriority.high => 2,
      };

  static TaskPriority fromDb(int value) => switch (value) {
        0 => TaskPriority.low,
        1 => TaskPriority.medium,
        2 => TaskPriority.high,
        _ => TaskPriority.medium,
      };

  String label() => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };
}

final class Task extends Equatable {
  final int? id;
  final String title;
  final String? description;

  final DateTime? deadline;
  final TaskPriority priority;

  final DateTime? scheduledAt;

  /// Used to cancel/reschedule reminders.
  final int? notificationId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    this.id,
    required this.title,
    this.description,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.scheduledAt,
    this.notificationId,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    DateTime? scheduledAt,
    int? notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        deadline,
        priority,
        scheduledAt,
        notificationId,
        createdAt,
        updatedAt,
      ];
}