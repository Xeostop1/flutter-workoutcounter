import 'dart:convert';
import 'package:flutter/foundation.dart'; // ← ChangeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class RoutineViewModel extends ChangeNotifier {
  List<Routine> _routines = [];

  List<Routine> get routines => List.unmodifiable(_routines);

  /// SharedPreferences에서 루틴 로드
  Future<void> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('routines') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);

    _routines = jsonList.map((e) => Routine.fromJson(e)).toList();

    // 샘플 데이터 자동 추가 (한 번만 실행)
    if (_routines.isEmpty) {
      _routines = [
        Routine(name: '스쿼트 루틴', sets: 3, reps: 15),
        Routine(name: '데드리프트 루틴', sets: 2, reps: 10),
        Routine(name: '푸쉬업 루틴', sets: 4, reps: 20),
      ];
      final seed = _routines.map((e) => e.toJson()).toList();
      await prefs.setString('routines', jsonEncode(seed));
    }

    notifyListeners(); // ← 로드 후 갱신 알림
  }

  /// 루틴 추가(저장)
  Future<void> saveRoutine(Routine routine) async {
    final prefs = await SharedPreferences.getInstance();

    // 메모리 상태 먼저 갱신
    _routines = [..._routines, routine];

    // 디스크 반영
    final jsonList = _routines.map((e) => e.toJson()).toList();
    await prefs.setString('routines', jsonEncode(jsonList));

    notifyListeners(); // ← 갱신 알림
  }

  /// 루틴 삭제
  Future<void> deleteRoutine(int index) async {
    if (index < 0 || index >= _routines.length) return;

    _routines.removeAt(index);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = _routines.map((e) => e.toJson()).toList();
    await prefs.setString('routines', jsonEncode(jsonList));

    notifyListeners(); // ← 갱신 알림
  }

  /// 전체 목록 가져오기(읽기 전용 용도)
  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('routines') ?? '[]';
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      debugPrint('🔥 Error decoding routines: $e');
      return [];
    }
  }

  /// 루틴 수정
  Future<void> updateRoutine(int index, Routine updatedRoutine) async {
    if (index < 0 || index >= _routines.length) return;

    _routines[index] = updatedRoutine;

    final prefs = await SharedPreferences.getInstance();
    final jsonList = _routines.map((e) => e.toJson()).toList();
    await prefs.setString('routines', jsonEncode(jsonList));

    notifyListeners(); // ← 갱신 알림
  }
}
