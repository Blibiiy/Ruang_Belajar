import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/datetime/datetime_ext.dart';
import '../../notifications/local_notification_service.dart';
import '../../tasks/bloc/task_bloc.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_form_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.high => AppColors.error,
        TaskPriority.medium => AppColors.tertiary,
        TaskPriority.low => AppColors.onSurfaceVariant,
      };

  int _generateNotifId() => DateTime.now().millisecondsSinceEpoch % 1000000000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruang Belajar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            final tasks = state.tasks;

            final unscheduled = tasks.where((t) => t.scheduledAt == null).toList()
              ..sort((a, b) {
                final pr = b.priority.toDb().compareTo(a.priority.toDb());
                if (pr != 0) return pr;
                final ad = a.deadline;
                final bd = b.deadline;
                if (ad == null && bd == null) return 0;
                if (ad == null) return 1;
                if (bd == null) return -1;
                return ad.compareTo(bd);
              });

            final scheduled = tasks.where((t) => t.scheduledAt != null).toList()
              ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

            final scheduledSoon = scheduled.where((t) {
              final s = t.scheduledAt!;
              final now = DateTime.now();
              return s.isAfter(now.subtract(const Duration(minutes: 1))) &&
                  s.isBefore(now.add(const Duration(days: 7)));
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => context.read<TaskBloc>().add(const TaskRefreshed()),
              child: ListView(
                children: [
                  _heroCard(tasks),
                  const SizedBox(height: 12),

                  _sectionHeader(
                    title: 'Unscheduled Tasks',
                    subtitle: '${unscheduled.length} Items',
                    actionText: 'Add',
                    onAction: () => _openAdd(context),
                  ),
                  const SizedBox(height: 10),

                  if (unscheduled.isEmpty)
                    _emptyCard('Semua task sudah dijadwalkan.')
                  else
                    ...unscheduled.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _taskCard(
                            context,
                            task: t,
                            leadingColor: _priorityColor(t.priority),
                            subtitle: _subtitleUnscheduled(t),
                            actionLabel: 'Schedule',
                            onAction: () => _scheduleOrReschedule(context, t),
                          ),
                        )),

                  const SizedBox(height: 16),

                  _sectionHeader(
                    title: 'Scheduled Soon',
                    subtitle: '${scheduledSoon.length} Items',
                    actionText: 'Calendar',
                    onAction: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buka tab Calendar untuk lihat semua jadwal.')),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  if (scheduledSoon.isEmpty)
                    _emptyCard('Belum ada jadwal dalam 7 hari ke depan.')
                  else
                    ...scheduledSoon.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _taskCard(
                            context,
                            task: t,
                            leadingColor: _priorityColor(t.priority),
                            subtitle: _subtitleScheduled(t),
                            actionLabel: 'Reschedule',
                            onAction: () => _scheduleOrReschedule(context, t),
                          ),
                        )),

                  const SizedBox(height: 90),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _heroCard(List<Task> tasks) {
    final scheduledCount = tasks.where((t) => t.scheduledAt != null).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Your learning environment is ready.',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tasks: ${tasks.length} • Scheduled: $scheduledCount',
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(color: AppColors.onSurfaceVariant)),
      ),
    );
  }

  Widget _taskCard(
    BuildContext context, {
    required Task task,
    required Color leadingColor,
    required String subtitle,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEdit(context, task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: leadingColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.onSurfaceVariant, height: 1.2),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => onAction(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(actionLabel, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openEdit(context, task);
                        } else if (value == 'delete') {
                          await _deleteTaskWithNotification(context, task);
                        } else if (value == 'schedule') {
                          await _scheduleOrReschedule(context, task);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'schedule',
                          child: Text(task.scheduledAt == null ? 'Schedule' : 'Reschedule'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TaskFormPage()),
    );
    if (created == true && context.mounted) {
      context.read<TaskBloc>().add(const TaskRefreshed());
    }
  }

  Future<void> _openEdit(BuildContext context, Task task) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskFormPage(editing: task)),
    );
    if (updated == true && context.mounted) {
      context.read<TaskBloc>().add(const TaskRefreshed());
    }
  }

  Future<void> _deleteTaskWithNotification(BuildContext context, Task task) async {
    final notifId = task.notificationId;
    if (notifId != null) {
      await LocalNotificationService.instance.cancel(notifId);
    }
    final id = task.id;
    if (id != null && context.mounted) {
      context.read<TaskBloc>().add(TaskDeleted(id));
      context.read<TaskBloc>().add(const TaskRefreshed());
    }
  }

  Future<void> _scheduleOrReschedule(BuildContext context, Task t) async {
    final now = DateTime.now();
    final initial = t.scheduledAt ??
        DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 5) * 5);

    final date = await showDatePicker(
      context: context,
      initialDate: initial.dateOnly,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // cancel old notif if exists
    final oldNotifId = t.notificationId;
    if (oldNotifId != null) {
      await LocalNotificationService.instance.cancel(oldNotifId);
    }

    final notifId = oldNotifId ?? _generateNotifId();

    final updated = t.copyWith(
      scheduledAt: scheduled,
      notificationId: notifId,
    );

    if (!context.mounted) return;
    context.read<TaskBloc>().add(TaskUpdated(updated));
    context.read<TaskBloc>().add(const TaskRefreshed());

    await LocalNotificationService.instance.scheduleTaskReminder(
      notificationId: notifId,
      when: scheduled,
      title: 'Ruang Belajar',
      body: 'Time to study: ${t.title}',
    );
  }

  String _subtitleUnscheduled(Task t) {
    final p = t.priority.label();
    final dl = t.deadline;
    if (dl == null) return 'Priority: $p';
    return 'Priority: $p • Deadline: ${_fmt(dl)}';
  }

  String _subtitleScheduled(Task t) {
    final s = t.scheduledAt!;
    final p = t.priority.label();
    return 'Scheduled: ${_fmt(s)} • Priority: $p';
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}