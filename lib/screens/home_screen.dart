import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 루틴 예시 데이터
    final routines = [
      {'name': '스쿼트', 'sets': 3, 'reps': 10},
      {'name': '데드리프트', 'sets': 3, 'reps': 10},
      {'name': '덩키킥', 'sets': 3, 'reps': 10},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Image.asset(
          'assets/images/logo.png', // 로고 이미지
          height: 28,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 마스코트 + 말풍선
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/firedefalut.png', // 마스코트 이미지
                    height: 64,
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/card_messege.png', // 말풍선 배경 이미지
                        height: 64, // 말풍선 높이 맞게 조절
                        width:
                            MediaQuery.of(context).size.width *
                            0.6, // 화면의 60% 너비
                        fit: BoxFit.contain,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16), // 텍스트 위치 조절
                        child: Text(
                          '오늘부터 시작이야!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 루틴 목록
            if (routines.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final r = routines[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${r['name']}   ${r['sets']}세트 ${r['reps']}회',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '루틴이 비어있어요!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '루틴을 추가해주세요 +',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80), // 네비게이션바 공간 확보
          ],
        ),
      ),

      // 하단 네비게이션바 + 중앙 PLAY 버튼
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 네비게이션바
          BottomNavigationBar(
            currentIndex: 0,
            selectedItemColor: Colors.deepOrange,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center),
                label: '운동',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '기록'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: '루틴'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            ],
            onTap: (index) {
              // TODO: 네비게이션 기능 추가
            },
          ),

          // 중앙 Play 버튼
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/workout');
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
