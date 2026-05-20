import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../tasks/bloc/task_bloc.dart';
import '../../tasks/domain/task.dart';

class PickTaskSheet extends StatelessWidget {
  const PickTaskSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose task to focus',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                final tasks = state.tasks;
                if (tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No tasks yet. Add a task first.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length + 1,
                    separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return ListTile(
                          leading: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                          title: const Text('No task (free focus)',
                              style: TextStyle(color: AppColors.onBackground)),
                          onTap: () => Navigator.of(context).pop<Task?>(null),
                        );
                      }

                      final t = tasks[i - 1];
                      return ListTile(
                        leading: const Icon(Icons.task_alt, color: AppColors.primary),
                        title: Text(t.title, style: const TextStyle(color: AppColors.onBackground)),
                        subtitle: Text(
                          t.priority.label(),
                          style: const TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                        onTap: () => Navigator.of(context).pop<Task>(t),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}