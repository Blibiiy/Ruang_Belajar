import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/shell/presentation/shell_page.dart';
import '../features/tasks/bloc/task_bloc.dart';
import '../features/tasks/data/task_db.dart';
import '../features/tasks/data/task_repository.dart';
import '../features/sessions/data/study_session_repository.dart';
import '../features/sessions/bloc/stats_bloc.dart';
import '../features/sessions/bloc/stats_event.dart';
import 'theme.dart';

class RuangBelajarApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const RuangBelajarApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final db = TaskDb.instance;
    final taskRepo = SqliteTaskRepository(db);
    final sessionRepo = SqliteStudySessionRepository(db);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TaskRepository>(create: (_) => taskRepo),
        RepositoryProvider<StudySessionRepository>(create: (_) => sessionRepo),

        // Provide camera list globally (Android only)
        RepositoryProvider<List<CameraDescription>>(create: (_) => cameras),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => TaskBloc(repo: ctx.read<TaskRepository>())..add(const TaskStarted()),
          ),
          BlocProvider(
            create: (ctx) =>
                StatsBloc(repo: ctx.read<StudySessionRepository>())..add(const StatsStarted()),
          ),
        ],
        child: MaterialApp(
          title: 'Ruang Belajar',
          debugShowCheckedModeBanner: false,
          theme: buildDarkTheme(),
          home: const ShellPage(),
        ),
      ),
    );
  }
}