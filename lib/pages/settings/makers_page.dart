import 'package:flutter/material.dart';

class MakersPage extends StatelessWidget {
  const MakersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('만든이들'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 상단 카피
          Positioned.fill(
            top: 24,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '스파클 팀 소개',
                    style: text.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '우린 당신의 첫 운동 파트너이자\n가장 오래가는 응원팀이에요',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 큰 반원 + 캐릭터들
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 360,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 반원 배경
                  Positioned(
                    bottom: -120,
                    left: -60,
                    right: -60,
                    child: Container(
                      height: 360,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBFBFBF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // 두 캐릭터
                  Positioned(
                    bottom: 0,
                    left: 32,
                    child: _MemberCard(
                      role: '개발',
                      name: '하나',
                      email: 'hana@naver.com',
                      asset: 'assets/images/development_character.png',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 32,
                    child: _MemberCard(
                      role: '디자인',
                      name: '나라',
                      email: 'lucy12q@naver.com',
                      asset: 'assets/images/designer character.png',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.role,
    required this.name,
    required this.email,
    required this.asset,
  });

  final String role;
  final String name;
  final String email;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 직책 칩
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF9E9E9E),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 이름
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        // 이메일
        Text(email, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        // 캐릭터 이미지
        Image.asset(asset, width: 120, height: 120, fit: BoxFit.contain),
      ],
    );
  }
}
