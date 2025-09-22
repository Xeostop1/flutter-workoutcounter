import 'package:flutter/material.dart';

/// 어디서든 호출:
/// final result = await showAppSheet<T>(context, title: '제목', child: ...);
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  required Widget child,
  Widget? primaryButton,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    isDismissible: isDismissible,
    builder: (_) => _AppSheetScaffold(
      title: title,
      child: child,
      primaryButton: primaryButton,
    ),
  );
}

class _AppSheetScaffold extends StatelessWidget {
  const _AppSheetScaffold({
    this.title,
    required this.child,
    this.primaryButton,
  });

  final String? title;
  final Widget child;
  final Widget? primaryButton;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: const Color(0xFF4B4B4B),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (title != null) ...[
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // slot
                  child,
                  if (primaryButton != null) ...[
                    const SizedBox(height: 18),
                    primaryButton!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
