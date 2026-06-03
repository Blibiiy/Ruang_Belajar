import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/datetime/datetime_ext.dart';
import '../../ai_scheduling/data/gemini_scheduling_service.dart';
import '../../ai_scheduling/presentation/auto_schedule_sheet.dart';
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
                    primaryActionText: 'Add',
                    onPrimaryAction: () => _openAdd(context),
                    secondaryActionText: 'Auto schedule',
                    onSecondaryAction: unscheduled.isEmpty
                        ? null
                        : () => _autoScheduleAllUnscheduled(context, unscheduled, scheduled),
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
                    primaryActionText: 'Calendar',
                    onPrimaryAction: () {
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

  Future<void> _autoScheduleAllUnscheduled(
    BuildContext context,
    List<Task> unscheduled,
    List<Task> scheduledExisting,
  ) async {
    final answers = await showModalBottomSheet<AutoScheduleAnswers>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      builder: (_) => const AutoScheduleSheet(),
    );
    if (answers == null) return;

    // loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final now = DateTime.now();
      final horizon = now.add(const Duration(days: 14)); // fallback for tasks w/out deadline

      final service = GeminiSchedulingService();
      final results = await service.createSchedule(
        req: AutoScheduleRequest(
          activeHours: answers.hours,
          activeDays: answers.activeDays,
          strategy: answers.strategy,
          bufferMinutes: answers.bufferMinutes,
          nowLocal: now,
          horizonEndLocal: horizon,
        ),
        unscheduledTasks: unscheduled.where((t) => t.id != null).toList(),
        existingScheduledTasks: scheduledExisting,
      );

      // Map results by taskId
      final byId = {for (final r in results) r.taskId: r.scheduledAtLocal};

      // Apply schedule with validation + auto-fix (no past, no exact-start conflict).
      final usedStartTimes = <int>{};
      for (final t in scheduledExisting) {
        final s = t.scheduledAt;
        if (s != null) usedStartTimes.add(s.millisecondsSinceEpoch);
      }

      DateTime clampToActiveWindow(DateTime dt) {
        // Only basic clamp: keep within active hours (same day) by moving forward to startHour if needed.
        final start = DateTime(dt.year, dt.month, dt.day, answers.hours.startHour, answers.hours.startMinute);
        final end = DateTime(dt.year, dt.month, dt.day, answers.hours.endHour, answers.hours.endMinute);

        if (dt.isBefore(start)) return start;
        if (!dt.isBefore(end)) {
          // move to next day start
          final nextDay = DateTime(dt.year, dt.month, dt.day).add(const Duration(days: 1));
          return DateTime(nextDay.year, nextDay.month, nextDay.day, answers.hours.startHour, answers.hours.startMinute);
        }
        return dt;
      }

      bool isActiveDay(DateTime dt) {
        if (answers.activeDays == ActiveDays.everyday) return true;
        // weekdays
        return dt.weekday >= DateTime.monday && dt.weekday <= DateTime.friday;
      }

      DateTime moveToNextActiveDayStart(DateTime dt) {
        var cur = dt;
        while (!isActiveDay(cur)) {
          final d = DateTime(cur.year, cur.month, cur.day).add(const Duration(days: 1));
          cur = DateTime(d.year, d.month, d.day, answers.hours.startHour, answers.hours.startMinute);
        }
        return cur;
      }

      DateTime nextAvailable(DateTime candidate) {
        var c = candidate;
        c = clampToActiveWindow(c);
        c = moveToNextActiveDayStart(c);

        // avoid past
        if (c.isBefore(now)) c = now.add(const Duration(minutes: 1));
        c = clampToActiveWindow(c);
        c = moveToNextActiveDayStart(c);

        // avoid exact-start conflicts; step by buffer minutes (>=1)
        final step = math.max(1, answers.bufferMinutes);
        while (usedStartTimes.contains(c.millisecondsSinceEpoch)) {
          c = c.add(Duration(minutes: step));
          c = clampToActiveWindow(c);
          c = moveToNextActiveDayStart(c);
        }
        usedStartTimes.add(c.millisecondsSinceEpoch);
        return c;
      }

      final updates = <Task>[];

      for (final t in unscheduled) {
        final id = t.id;
        if (id == null) continue;

        final proposed = byId[id];
        if (proposed == null) continue;

        // Respect deadline: if proposed after deadline, pull it back to <= deadline if possible.
        DateTime candidate = proposed;

        final dl = t.deadline;
        if (dl != null && candidate.isAfter(dl)) {
          // best effort: schedule at deadline minus small buffer, then normalize
          candidate = dl.subtract(Duration(minutes: math.max(1, answers.bufferMinutes)));
        }

        // If no deadline, keep within horizon.
        if (dl == null && candidate.isAfter(horizon)) {
          candidate = horizon.subtract(const Duration(hours: 1));
        }

        final scheduledAt = nextAvailable(candidate);

        // notif handling
        final oldNotifId = t.notificationId;
        if (oldNotifId != null) {
          await LocalNotificationService.instance.cancel(oldNotifId);
        }
        final notifId = oldNotifId ?? _generateNotifId();

        final updated = t.copyWith(
          scheduledAt: scheduledAt,
          notificationId: notifId,
        );
        updates.add(updated);

        await LocalNotificationService.instance.scheduleTaskReminder(
          notificationId: notifId,
          when: scheduledAt,
          title: 'Ruang Belajar',
          body: 'Time to study: ${t.title}',
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading

      if (updates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI tidak mengembalikan jadwal yang bisa dipakai.')),
        );
        return;
      }

      context.read<TaskBloc>().add(TasksBulkUpdated(updates));
      context.read<TaskBloc>().add(const TaskRefreshed());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto schedule selesai: ${updates.length} task dijadwalkan.')),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto schedule gagal: $e')),
        );
      }
    }
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
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
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
        if (secondaryActionText != null)
          TextButton(
            onPressed: onSecondaryAction,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(secondaryActionText),
          ),
        TextButton(
          onPressed: onPrimaryAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(primaryActionText),
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