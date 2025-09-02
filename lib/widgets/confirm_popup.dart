import 'package:flutter/material.dart';

/// 어디서나 쓸 수 있는 확인 팝업.
/// true(확인) / false(취소) 를 반환합니다.
Future<bool?> showConfirmPopup(
    BuildContext context, {
      required String title,
      String? message,
      String cancelText = '아니요',
      String okText = '네',
    }) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'confirm',
    barrierColor: Colors.black54,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (_, anim, __, ___) {
      // 위에서 아래로 살짝 떨어지는 애니메이션
      final offset = Tween<Offset>(
        begin: const Offset(0, -0.3),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim);

      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: offset,
            child: _ConfirmCard(
              title: title,
              message: message,
              cancelText: cancelText,
              okText: okText,
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 220),
  );
}

class _ConfirmCard extends StatelessWidget {
  final String title;
  final String? message;
  final String cancelText;
  final String okText;

  const _ConfirmCard({
    required this.title,
    this.message,
    required this.cancelText,
    required this.okText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 80), // 상단에서 내려오는 느낌
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('아니요',
                      style: TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '네',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF6B35), // 브랜드 오렌지
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
