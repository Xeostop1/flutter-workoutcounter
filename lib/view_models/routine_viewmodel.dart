import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/routine.dart';

class RoutineViewModel {
  List<Routine> _routines = [];

  /// 외부에서 읽기만 가능하도록 getter 제공
  List<Routine> get routines => _routines;

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
      final jsonList = _routines.map((e) => e.toJson()).toList();
      prefs.setString('routines', jsonEncode(jsonList));
    }
  }

  /// 루틴 저장
  // Future<void> saveRoutine(Routine routine) async {
  //   _routines.add(routine);
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonList = _routines.map((e) => e.toJson()).toList();
  //   prefs.setString('routines', jsonEncode(jsonList));
  // }

  Future<void> saveRoutine(Routine routine) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('routines') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<Routine> loaded = jsonList.map((e) => Routine.fromJson(e)).toList();

    loaded.add(routine); // 기존 루틴에 추가

    final updatedJson = jsonEncode(loaded.map((e) => e.toJson()).toList());
    await prefs.setString('routines', updatedJson);
  }



  /// 루틴 삭제
  Future<void> deleteRoutine(int index) async {
    _routines.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _routines.map((e) => e.toJson()).toList();
    prefs.setString('routines', jsonEncode(jsonList));
  }

  // SharedPreferences에서 불러오기
  // Future<List<Routine>> getRoutines() async {
  //   await loadRoutines();
  //   return routines;
  // }
  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('routines') ?? '[]';

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      print('🔥 Error decoding routines: $e');
      return [];
    }
  }


}
