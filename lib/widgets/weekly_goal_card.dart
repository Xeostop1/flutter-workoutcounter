import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/records_viewmodel.dart';

class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({super.key, this.footer});
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final target = context.select<AuthViewModel, int>(
      (auth) => auth.weeklyTarget ?? 3,
    );
    final settingsLoaded = context.select<AuthViewModel, bool>(
      (auth) => auth.settingsLoaded,
    );
    final records = context.watch<RecordsViewModel>();
    final loading = !settingsLoaded || records.isLoading;
    final failed = records.loadError != null;
    final completed = records.workoutsThisWeek();
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      key: const ValueKey('weekly-goal-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF34373E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '이번 주 목표',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loading || failed ? '— / $target회' : '$completed / $target회',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF895E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: loading
                  ? null
                  : failed
                  ? 0
                  : progress,
              minHeight: 6,
              color: const Color(0xFFFF784F),
              backgroundColor: const Color(0xFF383B42),
              semanticsLabel: '이번 주 운동 목표',
              semanticsValue: loading
                  ? '불러오는 중'
                  : failed
                  ? '운동 기록 확인 필요'
                  : '$target회 중 $completed회',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loading
                ? '목표와 기록을 불러오고 있어요.'
                : failed
                ? '운동 기록을 불러오지 못했어요.'
                : '주 $target회 운동하기',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBABDC6)),
          ),
          if (failed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: records.reload,
                child: const Text('다시 시도'),
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFF34373E)),
            footer!,
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
