import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/routines_viewmodel.dart';
import '../../viewmodels/records_viewmodel.dart';
import '../../viewmodels/counter_viewmodel.dart'; // ✅ 추가: 카운터에 루틴 붙일 때 필요

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutinesViewModel>();
    final records = context.watch<RecordsViewModel>();

    final day = _calcDay(records);
    final message = _buddyMessage(records);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_sporkle.png',
              height: 22,
              fit: BoxFit.contain,
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BuddyHeader(
            day: day,
            nickname: '나라',
            message: message,
            onTap: () => context.push('/buddy'),
          ),
          const SizedBox(height: 16),

          // 루틴 없이 운동하기
          Container(
            margin: const EdgeInsets.only(top: 37, bottom: 6),
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  context
                      .read<RoutinesViewModel>()
                      .clearSelectedRoutine(); // ✅ 선택 초기화
                  context.push('/counter'); // /counter로 이동
                },
                icon: Image.asset(
                  'assets/images/icon-play_s.png',
                  width: 24,
                  height: 24,
                ),
                label: const Text('루틴 없이 운동하기'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 저장된 루틴
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5D5D5D),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '저장된 루틴',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '1/${routines.allRoutines.isEmpty ? 1 : routines.allRoutines.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...routines.allRoutines.map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      dense: true,
                      title: Text(
                        r.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // ✅ 빈 리스트도 안전하게 표시
                      subtitle: Text(
                        _routineSubtitle(r),
                        style: const TextStyle(color: Color(0xFFBEBEBE)),
                      ),
                      trailing: _PlayPill(
                        onTap: () {
                          // ✅ 여기서 선택한 루틴을 카운터에 붙이고 이동
                          context.read<CounterViewModel>().attachRoutine(r);
                          context.go('/counter', extra: r);
                        },
                      ),
                      onTap: () {
                        // ✅ 리스트 아이템 탭해도 동일 동작
                        context.read<CounterViewModel>().attachRoutine(r);
                        context.go('/counter', extra: r);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 최초 기록일부터 오늘까지 경과일 (기록 없으면 Day 1)
  int _calcDay(RecordsViewModel rec) {
    final days = rec.allDays().toList()..sort();
    if (days.isEmpty) return 1;
    final first = DateTime(days.first.year, days.first.month, days.first.day);
    final today = DateTime.now();
    return today.difference(first).inDays + 1;
  }

  // 말풍선 메시지
  String _buddyMessage(RecordsViewModel rec) {
    final today = DateTime.now();
    final hasToday = rec.hasAnyOn(today);
    return hasToday ? '오늘도 고생했어!' : '아직 너무 어두워..';
  }

  // ✅ 루틴 아이템 수에 따라 안전하게 부제목 생성
  String _routineSubtitle(dynamic r) {
    final List items = (r.items as List?) ?? const [];
    if (items.isEmpty) return '운동 없음';
    final firstName = (items.first as dynamic).name?.toString() ?? '운동';
    if (items.length == 1) return firstName;
    return '$firstName 외 ${items.length - 1}개의 운동';
  }
}

// ===== 아바타 + Day 캡슐 + 닉네임 + 말풍선(이미지 배경) =====
class _BuddyHeader extends StatelessWidget {
  final int day;
  final String nickname;
  final String message;
  final VoidCallback onTap;

  const _BuddyHeader({
    required this.day,
    required this.nickname,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 회색 큰 원형 + 마스코트 PNG
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D5D5D),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  left: 26,
                  bottom: 12,
                  child: Image.asset(
                    'assets/images/charactor_first.png',
                    width: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // 오른쪽 텍스트 영역
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day 캡슐
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E5E5E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Day $day', // ✅ 실제 Day 표시
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(height: 3),

              // 닉네임
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$nickname ',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: '님의 불씨',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // 메시지 카드 (PNG 배경)
              Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/card_messege.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5D5D5D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 저장된 루틴 오른쪽 플레이 버튼
class _PlayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.asset(
          'assets/images/icon-play_L.png',
          width: 38,
          height: 37,
        ),
      ),
    );
  }
}
