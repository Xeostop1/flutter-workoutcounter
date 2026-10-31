import 'package:flutter/material.dart';

/// 어디서든 호출:
/// `final result = await showAppSheet<T>(context, child: ...)`
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
    barrierColor: Colors.black.withValues(alpha: 0.5),
    isDismissible: isDismissible,
    builder: (_) => _AppSheetScaffold(
      title: title,
      primaryButton: primaryButton,
      child: child,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: const Color(0xFF1C1E23),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF555862),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (title != null) ...[
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
      ),
    );
  }
}
