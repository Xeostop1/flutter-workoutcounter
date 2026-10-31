import 'package:flutter/material.dart';

Future<void> saveRoutineFavorite(
  BuildContext context,
  Future<void> Function() save,
) async {
  try {
    await save();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('즐겨찾기를 저장하지 못했어요. 다시 시도해주세요.')),
    );
  }
}
