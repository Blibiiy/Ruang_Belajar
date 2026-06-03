import 'package:sqflite/sqflite.dart';

import '../../tasks/data/task_db.dart';
import '../domain/focus_session_metrics.dart';

abstract interface class FocusMetricsRepository {
  Future<void> upsert(FocusSessionMetrics metrics);
  Future<FocusSessionMetrics?> getBySessionId(int sessionId);
  Future<Map<int, FocusSessionMetrics>> getBySessionIds(List<int> sessionIds);
}

final class SqliteFocusMetricsRepository implements FocusMetricsRepository {
  final TaskDb _db;
  SqliteFocusMetricsRepository(this._db);

  @override
  Future<void> upsert(FocusSessionMetrics metrics) async {
    final db = await _db.database;
    await db.insert(
      TaskDb.focusMetricsTable,
      _toRow(metrics),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<FocusSessionMetrics?> getBySessionId(int sessionId) async {
    final db = await _db.database;
    final rows = await db.query(
      TaskDb.focusMetricsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Map<int, FocusSessionMetrics>> getBySessionIds(List<int> sessionIds) async {
    if (sessionIds.isEmpty) return const {};

    final db = await _db.database;

    // Build: WHERE session_id IN (?, ?, ...)
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final rows = await db.query(
      TaskDb.focusMetricsTable,
      where: 'session_id IN ($placeholders)',
      whereArgs: sessionIds,
    );

    final map = <int, FocusSessionMetrics>{};
    for (final row in rows) {
      final m = _fromRow(row);
      map[m.sessionId] = m;
    }
    return map;
  }

  Map<String, Object?> _toRow(FocusSessionMetrics m) => {
        'session_id': m.sessionId,
        'focus_total_seconds': m.focusTotalSeconds,
        'focus_active_seconds': m.focusActiveSeconds,
        'absent_seconds': m.absentSeconds,
        'distracted_seconds': m.distractedSeconds,
        'fatigued_seconds': m.fatiguedSeconds,
        'absent_events': m.absentEvents,
        'distracted_events': m.distractedEvents,
        'fatigued_events': m.fatiguedEvents,
        'focus_score': m.focusScore,
        'created_at_ms': m.createdAt.millisecondsSinceEpoch,
      };

  FocusSessionMetrics _fromRow(Map<String, Object?> row) {
    return FocusSessionMetrics(
      sessionId: row['session_id'] as int,
      focusTotalSeconds: row['focus_total_seconds'] as int,
      focusActiveSeconds: row['focus_active_seconds'] as int,
      absentSeconds: row['absent_seconds'] as int,
      distractedSeconds: row['distracted_seconds'] as int,
      fatiguedSeconds: row['fatigued_seconds'] as int,
      absentEvents: row['absent_events'] as int,
      distractedEvents: row['distracted_events'] as int,
      fatiguedEvents: row['fatigued_events'] as int,
      focusScore: (row['focus_score'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at_ms'] as int),
    );
  }
}