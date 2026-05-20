part of 'task_bloc.dart';

enum TaskStatus { initial, loading, ready, failure }

final class TaskState extends Equatable {
  final TaskStatus status;
  final List<Task> tasks;
  final String? errorMessage;

  const TaskState({
    required this.status,
    required this.tasks,
    this.errorMessage,
  });

  const TaskState.initial()
      : status = TaskStatus.initial,
        tasks = const [],
        errorMessage = null;

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? tasks,
    String? errorMessage,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}