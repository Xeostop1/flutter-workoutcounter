import 'package:flutter/material.dart';

enum SocialBrand { apple, google }

class SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final SocialBrand brand;

  /// 브랜드 로고를 에셋으로 쓰고 싶으면 경로를 넘겨줘.
  /// (없으면 기본 아이콘으로 표시)
  final String? iconAsset;

  final double height;
  final double radius;

  const SocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.brand,
    this.iconAsset,
    this.height = 52,
    this.radius = 12,
  });

  /// 팩토리 생성자 (가독성)
  factory SocialButton.apple({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    String? iconAsset,
  }) => SocialButton(
    key: key,
    label: label,
    onPressed: onPressed,
    brand: SocialBrand.apple,
    iconAsset: iconAsset,
  );

  factory SocialButton.google({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    String? iconAsset,
  }) => SocialButton(
    key: key,
    label: label,
    onPressed: onPressed,
    brand: SocialBrand.google,
    iconAsset: iconAsset,
  );

  @override
  Widget build(BuildContext context) {
    final isApple = brand == SocialBrand.apple;

    // 스샷에 맞춘 기본 색
    final bg = isApple ? Colors.white : const Color(0xFFE6E6E6);
    final fg = Colors.black87;

    Widget icon;
    if (iconAsset != null) {
      icon = Image.asset(iconAsset!, width: 20, height: 20);
    } else {
      // 에셋이 없다면 임시 아이콘(원하면 나중에 교체)
      icon = Icon(isApple ? Icons.apple : Icons.g_mobiledata, size: 22);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
