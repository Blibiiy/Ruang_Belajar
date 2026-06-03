import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../focus_metrics/domain/focus_session_metrics.dart';
import '../domain/study_session.dart';

class SessionDetailPage extends StatelessWidget {
  final StudySession session;
  final FocusSessionMetrics? metrics;

  const SessionDetailPage({
    super.key,
    required this.session,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final started = session.startedAt;
    final ended = session.endedAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _row('Status', session.isCompleted ? 'Completed' : 'Stopped'),
                  _row('Started', _fmtFull(started)),
                  _row('Ended', _fmtFull(ended)),
                  _row('Focus', _mmss(session.focusSeconds)),
                  _row('Break', _mmss(session.breakSeconds)),
                  _row('Cycles', '${session.completedCycles}/${session.plannedCycles}'),
                  _row('Task ID', session.taskId?.toString() ?? '-'),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: metrics == null
                    ? const Text(
                        'Focus metrics belum tersedia untuk sesi ini.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Focus Metrics',
                            style: TextStyle(
                              color: AppColors.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _row('Focus Score', '${metrics!.focusScore}%'),
                          _row(
                            'Active Focus',
                            '${_mmss(metrics!.focusActiveSeconds)} / ${_mmss(metrics!.focusTotalSeconds)}',
                          ),
                          const SizedBox(height: 6),
                          _row('Absent', _mmss(metrics!.absentSeconds)),
                          _row('Distracted', _mmss(metrics!.distractedSeconds)),
                          _row('Fatigued', _mmss(metrics!.fatiguedSeconds)),
                          const SizedBox(height: 6),
                          _row('Absent events', metrics!.absentEvents.toString()),
                          _row('Distracted events', metrics!.distractedEvents.toString()),
                          _row('Fatigued events', metrics!.fatiguedEvents.toString()),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}