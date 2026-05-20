import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme.dart';
import '../../../core/datetime/datetime_ext.dart';
import '../../notifications/local_notification_service.dart';
import '../../tasks/bloc/task_bloc.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_form_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now().dateOnly;

  int _generateNotifId() => DateTime.now().millisecondsSinceEpoch % 1000000000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: const Color(0xFF003A3D),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TaskFormPage()),
          );
          if (created == true && context.mounted) {
            context.read<TaskBloc>().add(const TaskRefreshed());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            final tasks = state.tasks;

            final tasksForSelected = tasks.where((t) {
              final s = t.scheduledAt;
              if (s == null) return false;
              return s.dateOnly.isSameDay(_selectedDay);
            }).toList()
              ..sort((a, b) {
                final ad = a.scheduledAt;
                final bd = b.scheduledAt;
                if (ad == null && bd == null) return 0;
                if (ad == null) return 1;
                if (bd == null) return -1;
                return ad.compareTo(bd);
              });

            return Column(
              children: [
                _calendarCard(context, tasks),
                const SizedBox(height: 16),
                _header(tasksForSelected.length),
                const SizedBox(height: 10),
                Expanded(
                  child: tasksForSelected.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          itemCount: tasksForSelected.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final t = tasksForSelected[i];
                            return _taskCard(context, t);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _calendarCard(BuildContext context, List<Task> tasks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => day.dateOnly.isSameDay(_selectedDay),
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            titleCentered: false,
            formatButtonVisible: false,
            titleTextStyle: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
            rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AppColors.onSurfaceVariant),
            weekendStyle: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: AppColors.onBackground),
            weekendTextStyle: const TextStyle(color: AppColors.onBackground),
            outsideTextStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.35)),
            selectedDecoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
          ),
          eventLoader: (day) {
            final d = day.dateOnly;
            return tasks.where((t) => t.scheduledAt?.dateOnly.isSameDay(d) ?? false).toList();
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay.dateOnly;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ),
    );
  }

  Widget _header(int count) {
    final d = _selectedDay;
    final label =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tasks for $label',
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$count Items',
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Belum ada task yang dijadwalkan di hari ini.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, Task t) {
    final time = t.scheduledAt == null
        ? '--:--'
        : '${t.scheduledAt!.hour.toString().padLeft(2, '0')}:${t.scheduledAt!.minute.toString().padLeft(2, '0')}';

    final priorityColor = switch (t.priority) {
      TaskPriority.high => AppColors.error,
      TaskPriority.medium => AppColors.tertiaryContainer,
      TaskPriority.low => AppColors.onSurfaceVariant,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _rescheduleTask(context, t),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _priorityPill(t.priority),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.description ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityPill(TaskPriority p) {
    final (bg, fg, icon) = switch (p) {
      TaskPriority.high => (
          AppColors.errorContainer.withOpacity(0.2),
          AppColors.error,
          Icons.priority_high
        ),
      TaskPriority.medium => (
          AppColors.tertiaryContainer.withOpacity(0.2),
          AppColors.tertiary,
          Icons.remove
        ),
      TaskPriority.low => (
          AppColors.surfaceContainerHighest,
          AppColors.onSurfaceVariant,
          Icons.arrow_downward
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            p.label(),
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _rescheduleTask(BuildContext context, Task t) async {
    final now = DateTime.now();
    final initial = t.scheduledAt ??
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, now.hour, now.minute);

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

    final updated = t.copyWith(scheduledAt: scheduled, notificationId: notifId);

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
}