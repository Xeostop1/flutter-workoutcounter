import 'routine.dart';

class RoutineCategory {
  final String id;              // ✅ 카테고리 UUID (PK)
  final String name;            // 표시용 이름 (예: 하체)
  final List<Routine> routines; // 선택: 카테고리 하위에 미리 붙여둘 때

  const RoutineCategory({
    required this.id,
    required this.name,
    this.routines = const [],
  });
}
