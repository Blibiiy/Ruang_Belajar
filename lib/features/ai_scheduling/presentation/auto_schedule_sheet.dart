import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../data/gemini_scheduling_service.dart';

final class AutoScheduleAnswers {
  final ActiveDays activeDays;
  final ScheduleStrategy strategy;
  final TimeOfDayRange hours;
  final int bufferMinutes;

  const AutoScheduleAnswers({
    required this.activeDays,
    required this.strategy,
    required this.hours,
    required this.bufferMinutes,
  });
}

class AutoScheduleSheet extends StatefulWidget {
  const AutoScheduleSheet({super.key});

  @override
  State<AutoScheduleSheet> createState() => _AutoScheduleSheetState();
}

class _AutoScheduleSheetState extends State<AutoScheduleSheet> {
  ActiveDays _activeDays = ActiveDays.weekdays;
  ScheduleStrategy _strategy = ScheduleStrategy.deadlineFirst;

  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 22, minute: 0);

  int _bufferMinutes = 10;

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t == null) return;
    setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t == null) return;
    setState(() => _end = t);
  }

  void _submit() {
    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai harus lebih besar dari jam mulai.')),
      );
      return;
    }

    Navigator.of(context).pop(
      AutoScheduleAnswers(
        activeDays: _activeDays,
        strategy: _strategy,
        hours: TimeOfDayRange(
          startHour: _start.hour,
          startMinute: _start.minute,
          endHour: _end.hour,
          endMinute: _end.minute,
        ),
        bufferMinutes: _bufferMinutes.clamp(0, 120),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Auto Schedule (AI)',
              style: TextStyle(
                color: AppColors.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jawab beberapa pertanyaan, lalu AI akan menjadwalkan semua task yang masih Unscheduled.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            _card(
              title: 'Hari aktif',
              child: DropdownButtonFormField<ActiveDays>(
                value: _activeDays,
                dropdownColor: AppColors.surfaceContainerHigh,
                items: const [
                  DropdownMenuItem(value: ActiveDays.weekdays, child: Text('Weekdays (Mon-Fri)')),
                  DropdownMenuItem(value: ActiveDays.everyday, child: Text('Everyday (Mon-Sun)')),
                ],
                onChanged: (v) => setState(() => _activeDays = v ?? ActiveDays.weekdays),
              ),
            ),
            const SizedBox(height: 10),

            _card(
              title: 'Strategi penjadwalan',
              child: DropdownButtonFormField<ScheduleStrategy>(
                value: _strategy,
                dropdownColor: AppColors.surfaceContainerHigh,
                items: const [
                  DropdownMenuItem(value: ScheduleStrategy.deadlineFirst, child: Text('Deadline first')),
                  DropdownMenuItem(value: ScheduleStrategy.priorityFirst, child: Text('Priority first')),
                ],
                onChanged: (v) => setState(() => _strategy = v ?? ScheduleStrategy.deadlineFirst),
              ),
            ),
            const SizedBox(height: 10),

            _card(
              title: 'Jam aktif',
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStart,
                      child: Text('Mulai: ${_start.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEnd,
                      child: Text('Selesai: ${_end.format(context)}'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            _card(
              title: 'Buffer antar task (menit)',
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _bufferMinutes.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '$_bufferMinutes',
                      onChanged: (v) => setState(() => _bufferMinutes = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_bufferMinutes',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: const Color(0xFF003A3D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          child: child,
        ),
      ]),
    );
  }
}