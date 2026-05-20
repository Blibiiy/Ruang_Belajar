import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../bloc/task_bloc.dart';
import '../domain/task.dart';

class TaskFormPage extends StatefulWidget {
  final Task? editing;
  const TaskFormPage({super.key, this.editing});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _desc;

  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    final t = widget.editing;
    _title = TextEditingController(text: t?.title ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    _deadline = t?.deadline;
    _priority = t?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title wajib diisi')),
      );
      return;
    }

    final now = DateTime.now();
    final editing = widget.editing;

    if (editing == null) {
      final newTask = Task(
        title: title,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        deadline: _deadline,
        priority: _priority,
        scheduledAt: null,
        createdAt: now,
        updatedAt: now,
      );
      context.read<TaskBloc>().add(TaskCreated(newTask));
    } else {
      final updated = editing.copyWith(
        title: title,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        deadline: _deadline,
        priority: _priority,
      );
      context.read<TaskBloc>().add(TaskUpdated(updated));
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            _fieldLabel('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              style: const TextStyle(color: AppColors.onBackground, fontSize: 16),
              decoration: _inputDecoration(hint: 'e.g., Read Chapter 4'),
            ),
            const SizedBox(height: 16),

            _fieldLabel('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 4,
              style: const TextStyle(color: AppColors.onBackground),
              decoration: _inputDecoration(hint: 'Add notes, links, or details...'),
            ),
            const SizedBox(height: 16),

            _fieldLabel('Deadline'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.onSurfaceVariant, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _deadline == null ? 'Set date & time' : _fmt(_deadline!),
                        style: TextStyle(
                          color: _deadline == null ? AppColors.onSurfaceVariant : AppColors.onBackground,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _fieldLabel('Priority'),
            const SizedBox(height: 8),
            _prioritySegment(),
          ],
        ),
      ),

      // sticky bottom action area (mirip HTML kamu)
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withOpacity(0.95),
            border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // MVP: tombol AI belum berfungsi, tapi UI-nya ada dulu
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI scheduling belum termasuk MVP (nanti di fase next).')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Ask AI to Schedule'),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: const Color(0xFF003A3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prioritySegment() {
    Widget chip(TaskPriority p) {
      final selected = _priority == p;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _priority = p),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceContainerHighest : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              p.label(),
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          chip(TaskPriority.low),
          chip(TaskPriority.medium),
          chip(TaskPriority.high),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      );

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
      );

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}