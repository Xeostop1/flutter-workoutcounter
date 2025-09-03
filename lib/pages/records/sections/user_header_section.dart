import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class UserHeaderSection extends StatelessWidget {
  const UserHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthViewModel, String>(
      (vm) => vm.displayName ?? '사용자',
    );
    final weekly = context.select<AuthViewModel, int?>(
      (vm) => vm.weeklyTarget, // 온보딩에서 저장된 값 (없으면 null)
    );
    final goalText = '“주 ${weekly ?? 3}회 운동하기 ”'; // 기본 3회

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아바타 + 이름 + 프로필수정
        Row(
          children: [
            _Avatar(size: 56, imageUrl: context.read<AuthViewModel>().photoUrl),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/settings'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '프로필 수정',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // “주 3회 운동하기”
        Text(
          goalText,
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.imageUrl});
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF5D5D5D),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.black87, size: 28),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
