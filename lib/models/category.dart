// lib/models/category.dart
class Category {
  final String id;      // ✅ DB PK (uuid)
  final String code;    // ✅ 사람이 읽는 키 ('lower', 'back' ...)
  final String nameKo;  // 표시 이름 (하체, 등, ...)
  const Category({
    required this.id,
    required this.code,
    required this.nameKo,
  });
}
