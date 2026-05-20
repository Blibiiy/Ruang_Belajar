import 'package:sqflite/sqflite.dart';
import '../../tasks/data/task_db.dart';
import '../domain/study_session.dart';

abstract interface class StudySessionRepository {
  Future<StudySession> insert(StudySession session);
  Future<List<StudySession>> getLatest({int limit = 200});
  Future<List<StudySession>> getBetween(DateTime from, DateTime to);
}

final class SqliteStudySessionRepository implements StudySessionRepository {
  final TaskDb _db;
  SqliteStudySessionRepository(this._db);

  @override
  Future<StudySession> insert(StudySession session) async {
    final db = await _db.database;
    final id = await db.insert(TaskDb.sessionsTable, _toRow(session));
    return StudySession(
      id: id,
      taskId: session.taskId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      focusSeconds: session.focusSeconds,
      breakSeconds: session.breakSeconds,
      plannedCycles: session.plannedCycles,
      completedCycles: session.completedCycles,
      isCompleted: session.isCompleted,
      createdAt: session.createdAt,
    );
  }

  @override
  Future<List<StudySession>> getLatest({int limit = 200}) async {
    final db = await _db.database;
    final rows = await db.query(
      TaskDb.sessionsTable,
      orderBy: 'started_at_ms DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<StudySession>> getBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      TaskDb.sessionsTable,
      where: 'started_at_ms >= ? AND started_at_ms < ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'started_at_ms ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Map<String, Object?> _toRow(StudySession s) => {
        'id': s.id,
        'task_id': s.taskId,
        'started_at_ms': s.startedAt.millisecondsSinceEpoch,
        'ended_at_ms': s.endedAt.millisecondsSinceEpoch,
        'focus_seconds': s.focusSeconds,
        'break_seconds': s.breakSeconds,
        'planned_cycles': s.plannedCycles,
        'completed_cycles': s.completedCycles,
        'is_completed': s.isCompleted ? 1 : 0,
        'created_at_ms': s.createdAt.millisecondsSinceEpoch,
      };

  StudySession _fromRow(Map<String, Object?> row) {
    return StudySession(
      id: row['id'] as int,
      taskId: row['task_id'] as int?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at_ms'] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at_ms'] as int),
      focusSeconds: row['focus_seconds'] as int,
      breakSeconds: row['break_seconds'] as int,
      plannedCycles: row['planned_cycles'] as int,
      completedCycles: row['completed_cycles'] as int,
      isCompleted: (row['is_completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at_ms'] as int),
    );
  }
}