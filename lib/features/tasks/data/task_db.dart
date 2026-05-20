import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final class TaskDb {
  TaskDb._();
  static final TaskDb instance = TaskDb._();

  static const _dbName = 'ruang_belajar.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null) return db;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute(_createTasksTableSql);
        await db.execute(_createSessionsTableSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createSessionsTableSql);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tasksTable ADD COLUMN notification_id INTEGER;');
        }
      },
    );

    return _db!;
  }

  static const tasksTable = 'tasks';
  static const sessionsTable = 'study_sessions';

  static const _createTasksTableSql = '''
CREATE TABLE $tasksTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  deadline_ms INTEGER,
  scheduled_at_ms INTEGER,
  priority INTEGER NOT NULL,
  notification_id INTEGER,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);
''';

  static const _createSessionsTableSql = '''
CREATE TABLE $sessionsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  task_id INTEGER,

  started_at_ms INTEGER NOT NULL,
  ended_at_ms INTEGER NOT NULL,

  focus_seconds INTEGER NOT NULL,
  break_seconds INTEGER NOT NULL,

  planned_cycles INTEGER NOT NULL,
  completed_cycles INTEGER NOT NULL,

  is_completed INTEGER NOT NULL,
  created_at_ms INTEGER NOT NULL
);
''';
}