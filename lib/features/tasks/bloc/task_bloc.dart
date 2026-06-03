import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

part 'task_event.dart';
part 'task_state.dart';

final class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repo;

  TaskBloc({required this.repo}) : super(const TaskState.initial()) {
    on<TaskStarted>(_onStarted);
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TasksBulkUpdated>(_onBulkUpdated);
    on<TaskDeleted>(_onDeleted);
    on<TaskRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(TaskStarted event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshed(TaskRefreshed event, Emitter<TaskState> emit) async {
    try {
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TaskState> emit) async {
    try {
      await repo.insert(event.task);
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdated(TaskUpdated event, Emitter<TaskState> emit) async {
    try {
      await repo.update(event.task);
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onBulkUpdated(TasksBulkUpdated event, Emitter<TaskState> emit) async {
    try {
      for (final t in event.tasks) {
        await repo.update(t);
      }
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TaskState> emit) async {
    try {
      await repo.delete(event.id);
      final tasks = await repo.getAll();
      emit(state.copyWith(status: TaskStatus.ready, tasks: tasks));
    } catch (e) {
      emit(state.copyWith(status: TaskStatus.failure, errorMessage: e.toString()));
    }
  }
}