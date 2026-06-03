part of 'task_bloc.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

final class TaskStarted extends TaskEvent {
  const TaskStarted();
}

final class TaskRefreshed extends TaskEvent {
  const TaskRefreshed();
}

final class TaskCreated extends TaskEvent {
  final Task task;
  const TaskCreated(this.task);

  @override
  List<Object?> get props => [task];
}

final class TaskUpdated extends TaskEvent {
  final Task task;
  const TaskUpdated(this.task);

  @override
  List<Object?> get props => [task];
}

final class TasksBulkUpdated extends TaskEvent {
  final List<Task> tasks;
  const TasksBulkUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

final class TaskDeleted extends TaskEvent {
  final int id;
  const TaskDeleted(this.id);

  @override
  List<Object?> get props => [id];
}