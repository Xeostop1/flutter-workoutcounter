import 'package:flutter/material.dart';

ThemeData appTheme() {
  const seed = Color(0xFFE65400); // deep orange
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFDF2EC),
  );
}
