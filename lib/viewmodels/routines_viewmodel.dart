import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';

/// 루틴 정렬 옵션
enum RoutineOrder {
  recent,       // 추가된 순서 (기본)
  titleAsc,     // 제목 오름차순
  titleDesc,    // 제목 내림차순
  favoriteFirst // 즐겨찾기 먼저
}

/// 루틴/카테고리 상태
class RoutinesViewModel extends ChangeNotifier {
  // DB/시드에서 로드되는 데이터
  List<RoutineCategory> categories = [];
  List<Routine> allRoutines = [];

  String? _selectedRoutineId;
  String? get selectedRoutineId => _selectedRoutineId;


  Routine? get selected =>
      _selectedRoutineId == null ? null : getById(_selectedRoutineId!);

  void selectRoutine(String id) {
    if (_selectedRoutineId == id) return;
    _selectedRoutineId = id;
    notifyListeners();
  }
  // ✅ 추가: 선택 해제(루틴 없이 운동하기용)
  void clearSelectedRoutine() {
    if (_selectedRoutineId == null) return;
    _selectedRoutineId = null;
    notifyListeners();
  }

  Routine? getById(String id) {
    try {
      return allRoutines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // 선택된 카테고리(UUID)
  String? selectedCategoryId;

  // ✅ 정렬 상태(기본: recent)
  RoutineOrder _order = RoutineOrder.recent;
  RoutineOrder get order => _order;

  // 즐겨찾기(루틴 id 집합) — 모델을 안 바꾸고도 즐겨찾기 정렬/표시 가능
  final Set<String> _favoriteIds = {};

  // -----------------------------------------
  // 초기 로드
  void loadSeed({
    required List<RoutineCategory> cats,
    required List<Routine> routines,
  }) {
    categories = cats;
    allRoutines = routines;
    selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
    notifyListeners();
  }

  // 카테고리 이름
  String categoryNameById(String id) {
    final found = categories.where((c) => c.id == id);
    return found.isEmpty ? '기타' : found.first.name;
  }

  // 카테고리 선택
  void selectCategory(String id) {
    if (selectedCategoryId == id) return;
    selectedCategoryId = id;
    notifyListeners();
  }

  // -----------------------------------------
  // ✅ 정렬 상태 변경
  void setOrder(RoutineOrder newOrder) {
    if (_order == newOrder) return;
    _order = newOrder;
    notifyListeners();
  }

  // ✅ 즐겨찾기 토글/조회
  void toggleFavorite(String routineId) {
    if (_favoriteIds.contains(routineId)) {
      _favoriteIds.remove(routineId);
    } else {
      _favoriteIds.add(routineId);
    }
    notifyListeners();
  }

  bool isFavorite(String routineId) => _favoriteIds.contains(routineId);

  // -----------------------------------------
  // 카테고리 내 루틴(정렬 적용)
  List<Routine> routinesByCategoryId(String categoryId) {
    return allRoutines.where((r) => r.categoryId == categoryId).toList();
  }

  List<Routine> routinesByCategoryIdOrdered(String categoryId) {
    final list = routinesByCategoryId(categoryId);

    switch (_order) {
      case RoutineOrder.recent:
      // 시드/DB에서 들어온 순서를 유지
        return List<Routine>.from(list);

      case RoutineOrder.titleAsc:
        return List<Routine>.from(list)
          ..sort((a, b) => a.title.compareTo(b.title));

      case RoutineOrder.titleDesc:
        return List<Routine>.from(list)
          ..sort((a, b) => b.title.compareTo(a.title));

      case RoutineOrder.favoriteFirst:
        return List<Routine>.from(list)
          ..sort((a, b) {
            final af = _favoriteIds.contains(a.id) ? 1 : 0;
            final bf = _favoriteIds.contains(b.id) ? 1 : 0;
            // 즐겨찾기(true) 우선, 그다음 제목
            final favCmp = bf.compareTo(af);
            return favCmp != 0 ? favCmp : a.title.compareTo(b.title);
          });
    }
  }
}
