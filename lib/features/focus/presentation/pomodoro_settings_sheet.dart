import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../bloc/focus_timer_bloc.dart';
import '../bloc/focus_timer_event.dart';
import '../bloc/focus_timer_state.dart';

class PomodoroSettingsSheet extends StatefulWidget {
  const PomodoroSettingsSheet({super.key});

  @override
  State<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<PomodoroSettingsSheet> {
  final _focusMinCtrl = TextEditingController();
  final _focusSecCtrl = TextEditingController();
  final _breakMinCtrl = TextEditingController();
  final _breakSecCtrl = TextEditingController();
  final _cyclesCtrl = TextEditingController();

  bool _inited = false;

  @override
  void dispose() {
    _focusMinCtrl.dispose();
    _focusSecCtrl.dispose();
    _breakMinCtrl.dispose();
    _breakSecCtrl.dispose();
    _cyclesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BlocBuilder<FocusTimerBloc, FocusTimerState>(
        builder: (context, state) {
          if (!_inited) {
            _inited = true;
            _focusMinCtrl.text = (state.focusSeconds ~/ 60).toString();
            _focusSecCtrl.text = (state.focusSeconds % 60).toString().padLeft(2, '0');
            _breakMinCtrl.text = (state.breakSeconds ~/ 60).toString();
            _breakSecCtrl.text = (state.breakSeconds % 60).toString().padLeft(2, '0');
            _cyclesCtrl.text = state.totalCycles.toString();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _grabHandle(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pomodoro Settings',
                    style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _timeRow(
                  title: 'Focus duration',
                  minCtrl: _focusMinCtrl,
                  secCtrl: _focusSecCtrl,
                ),
                const SizedBox(height: 10),
                _timeRow(
                  title: 'Break duration',
                  minCtrl: _breakMinCtrl,
                  secCtrl: _breakSecCtrl,
                  allowZero: true,
                ),
                const SizedBox(height: 10),

                _numberRow(
                  title: 'Cycles',
                  controller: _cyclesCtrl,
                  hint: '1-12',
                ),

                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => _save(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: const Color(0xFF003A3D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _grabHandle() {
    return Container(
      width: 44,
      height: 5,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.outlineVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _timeRow({
    required String title,
    required TextEditingController minCtrl,
    required TextEditingController secCtrl,
    bool allowZero = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _numField(
                controller: minCtrl,
                label: 'Minutes',
                hint: allowZero ? '0-180' : '0-180',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numField(
                controller: secCtrl,
                label: 'Seconds',
                hint: '0-59',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          allowZero
              ? 'Break boleh 0:00 (langsung lanjut cycle berikutnya)'
              : 'Focus minimal 0:01',
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _numberRow({
    required String title,
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w700,
                )),
          ),
          SizedBox(
            width: 110,
            child: _numField(controller: controller, label: 'x', hint: hint),
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
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
        isDense: true,
      ),
    );
  }

  void _save(BuildContext context) {
    int parseInt(TextEditingController c, {required int fallback}) {
      final raw = c.text.trim();
      final v = int.tryParse(raw);
      return v ?? fallback;
    }

    final focusMin = parseInt(_focusMinCtrl, fallback: 25).clamp(0, 180);
    final focusSec = parseInt(_focusSecCtrl, fallback: 0).clamp(0, 59);
    final breakMin = parseInt(_breakMinCtrl, fallback: 5).clamp(0, 60);
    final breakSec = parseInt(_breakSecCtrl, fallback: 0).clamp(0, 59);
    final cycles = parseInt(_cyclesCtrl, fallback: 1).clamp(1, 12);

    // enforce focus at least 1 second
    if ((focusMin * 60 + focusSec) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Focus duration minimal 0:01')),
      );
      return;
    }

    context.read<FocusTimerBloc>().add(
          FocusTimerSettingsUpdated(
            focusMinutes: focusMin,
            focusSeconds: focusSec,
            breakMinutes: breakMin,
            breakSeconds: breakSec,
            cycles: cycles,
          ),
        );
    Navigator.of(context).pop();
  }
}