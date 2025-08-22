import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ★ 라우팅을 위해 추가

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 라이트 블루 배경 (시안 톤)
    const bg = Color(0xFFEAF0FB);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
        child: FloatingActionButton.large(
          backgroundColor: Colors.white,
          onPressed: () {
            // ★ PLAY → 카운터 페이지로 이동
            context.push('/counter');
          },
          child: const Icon(
            Icons.play_arrow,
            color: Colors.deepOrange,
            size: 40,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 로고
              SizedBox(
                height: 28,
                child: Image.asset(
                  'assets/images/logo.png', // 네 에셋명으로 교체
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // 마스코트 + 말풍선 카드
              const _MascotSpeechCard(
                dayLabel: 'Day 1. 황조롱이새',
                message: '오늘도 할 수 있다!',
                mascotAsset: 'assets/images/firedefalut.png', // 교체
                balloonAsset: 'assets/images/card_messege.png', // 교체
              ),
              const SizedBox(height: 24),

              // 섹션 타이틀
              Row(
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '저장된 루틴',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 루틴 리스트 박스
              _RoutineBox(
                items: const [
                  _RoutineItem(title: '등', subtitle: '3 set · 12회'),
                  _RoutineItem(title: '하체', subtitle: '3 set · 15회'),
                ],
                onItemTap: (item) {
                  // ★ 루틴 카드 탭 → 카운터로 이동
                  context.push('/counter');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 마스코트 + 말풍선 카드(이미지 그대로 사용, 텍스트만 오버레이)
class _MascotSpeechCard extends StatelessWidget {
  final String dayLabel;
  final String message;
  final String mascotAsset;
  final String balloonAsset;

  const _MascotSpeechCard({
    required this.dayLabel,
    required this.message,
    required this.mascotAsset,
    required this.balloonAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(mascotAsset, width: 68, height: 68),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    balloonAsset,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5A3C28),
                        ),
                      ),
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
}

class _RoutineItem {
  final String title;
  final String subtitle;
  const _RoutineItem({required this.title, required this.subtitle});
}

/// 흰 카드 안에 줄 나눔으로 루틴 표기 (시안 스타일)
class _RoutineBox extends StatelessWidget {
  final List<_RoutineItem> items;
  final void Function(_RoutineItem) onItemTap;
  const _RoutineBox({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: () => onItemTap(items[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.star_border, color: Colors.black45),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFEFEFEF)),
          ],
        ],
      ),
    );
  }
}
