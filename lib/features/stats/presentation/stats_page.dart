import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../sessions/bloc/stats_bloc.dart';
import '../../sessions/bloc/stats_event.dart';
import '../../sessions/bloc/stats_state.dart';
import '../../sessions/domain/study_session.dart';
import '../../sessions/presentation/session_detail_page.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatsView();
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            if (state.status == StatsStatus.loading || state.status == StatsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == StatsStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Error',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            // DEBUG: harus kelihatan merah
            final debugHeader = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEBUG: StatsPage (features/stats) with Session History',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Text(
                  'DEBUG: latestSessions=${state.latestSessions.length}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
            );

            final todayFocusMin = (state.todayFocusSeconds / 60).floor();
            final todayBreakMin = (state.todayBreakSeconds / 60).floor();

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final totalsByDay = <DateTime, int>{};
            for (int i = 0; i < 7; i++) {
              final d = today.subtract(Duration(days: i));
              totalsByDay[d] = 0;
            }
            for (final s in state.last7DaysSessions) {
              final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
              if (totalsByDay.containsKey(d)) {
                totalsByDay[d] = (totalsByDay[d] ?? 0) + s.focusSeconds;
              }
            }
            final entries = totalsByDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

            return RefreshIndicator(
              onRefresh: () async => context.read<StatsBloc>().add(const StatsRefreshed()),
              child: ListView(
                children: [

                  _kpiCard(
                    title: 'Today',
                    lines: [
                      'Focus: ${todayFocusMin}m',
                      'Break: ${todayBreakMin}m',
                      'Completed sessions: ${state.todayCompletedSessions}',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _kpiCard(
                    title: 'Last 7 days (focus minutes)',
                    child: Column(
                      children: entries.map((e) {
                        final min = (e.value / 60).floor();
                        final label =
                            '${e.key.month.toString().padLeft(2, '0')}-${e.key.day.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: Text(label,
                                    style: const TextStyle(color: AppColors.onSurfaceVariant)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: (min / 240).clamp(0, 1),
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.primaryContainer,
                                    ),
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$min m',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: AppColors.onBackground),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _sessionHistoryCard(context, state.latestSessions),

                  const SizedBox(height: 90),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sessionHistoryCard(BuildContext context, List<StudySession> sessions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Session History (Latest)',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const Text(
              'Belum ada riwayat sesi.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            )
          else
            ...sessions.map((s) => _sessionRow(context, s)).toList(),
        ]),
      ),
    );
  }

  Widget _sessionRow(BuildContext context, StudySession s) {
    final statusColor = s.isCompleted ? AppColors.primary : AppColors.onSurfaceVariant;
    final statusText = s.isCompleted ? 'Completed' : 'Stopped';

    final start = s.startedAt;
    final label =
        '${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    final focus = _mmss(s.focusSeconds);
    final brk = _mmss(s.breakSeconds);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SessionDetailPage(session: s)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Focus $focus • Break $brk • Cycles ${s.completedCycles}/${s.plannedCycles}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withOpacity(0.25)),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    List<String>? lines,
    Widget? child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (lines != null)
            ...lines.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(t, style: const TextStyle(color: AppColors.onSurfaceVariant)),
                )),
          if (child != null) child,
        ]),
      ),
    );
  }

  String _mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}