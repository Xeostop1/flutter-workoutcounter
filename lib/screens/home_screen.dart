import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 예시 루틴 데이터 (필요시 ViewModel로 교체)
    final routines = const [
      {'name': '등'},
      {'name': '하체'},
      {'name': '상체'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3EA), // 배경 톤 (이미지 느낌에 맞춤)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Image.asset('assets/images/logo.png', height: 28),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 본문
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ====== (기존) 마스코트 + 말풍선 ======
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/firedefalut.png',
                          height: 64,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/card_messege.png',
                                height: 64,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Text(
                                  '오늘도 할 수 있다!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ====== 저장된 루틴 타이틀 ======
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/firedefalut.png',
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '저장된 루틴',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ====== 루틴 카드 리스트 ======
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: List.generate(routines.length, (i) {
                        final name = routines[i]['name'] as String;
                        return Column(
                          children: [
                            _RoutineRow(title: name),
                            if (i != routines.length - 1)
                              const Divider(
                                height: 16,
                                thickness: 1,
                                color: Color(0xFFEDEDED),
                                indent: 24,
                                endIndent: 24,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // ====== 오른쪽 하단 PLAY 버튼 (GoRouter로 이동) ======
            Positioned(
              right: 20,
              bottom: 24,
              child: GestureDetector(
                onTap: () => context.go('/workout'),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFFF6A2A),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Text(
                          'PLAY',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 체크박스 모양 + 제목 한 줄
class _RoutineRow extends StatelessWidget {
  final String title;
  const _RoutineRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD7D7D7), width: 2),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
