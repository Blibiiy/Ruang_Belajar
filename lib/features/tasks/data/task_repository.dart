import 'package:sqflite/sqflite.dart';
import '../domain/task.dart';
import 'task_db.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getAll();
  Future<Task> insert(Task task);
  Future<void> update(Task task);
  Future<void> delete(int id);
  Future<Task?> getById(int id);
}

final class SqliteTaskRepository implements TaskRepository {
  final TaskDb _db;

  SqliteTaskRepository(this._db);

  @override
  Future<List<Task>> getAll() async {
    final Database db = await _db.database;
    final rows = await db.query(
      TaskDb.tasksTable,
      orderBy: 'updated_at_ms DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Task?> getById(int id) async {
    final Database db = await _db.database;
    final rows = await db.query(
      TaskDb.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
    }

  @override
  Future<Task> insert(Task task) async {
    final Database db = await _db.database;
    final now = DateTime.now();
    final toInsert = task.copyWith(createdAt: now, updatedAt: now);

    final id = await db.insert(TaskDb.tasksTable, _toRow(toInsert));
    return toInsert.copyWith(id: id);
  }

  @override
  Future<void> update(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update task without id');
    }
    final Database db = await _db.database;
    final updated = task.copyWith(updatedAt: DateTime.now());

    await db.update(
      TaskDb.tasksTable,
      _toRow(updated),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final Database db = await _db.database;
    await db.delete(
      TaskDb.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(Task t) => <String, Object?>{
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'deadline_ms': t.deadline?.millisecondsSinceEpoch,
        'scheduled_at_ms': t.scheduledAt?.millisecondsSinceEpoch,
        'priority': t.priority.toDb(),
        'created_at_ms': t.createdAt.millisecondsSinceEpoch,
        'updated_at_ms': t.updatedAt.millisecondsSinceEpoch,
      };

  Task _fromRow(Map<String, Object?> row) {
    return Task(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      deadline: (row['deadline_ms'] as int?)?.let(DateTime.fromMillisecondsSinceEpoch),
      scheduledAt: (row['scheduled_at_ms'] as int?)?.let(DateTime.fromMillisecondsSinceEpoch),
      priority: TaskPriorityX.fromDb(row['priority'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at_ms'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at_ms'] as int),
    );
  }
}

/// helper kecil biar rapi (Dart 3.9)
extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}