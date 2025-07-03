import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/routine.dart';

class RoutineViewModel {
  List<Routine> routines = [];

  Future<void> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('routines') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    routines = jsonList.map((e) => Routine.fromJson(e)).toList();
  }

  Future<void> saveRoutine(Routine routine) async {
    routines.add(routine); // 메모리에도 추가
    final prefs = await SharedPreferences.getInstance();
    final jsonList = routines.map((e) => e.toJson()).toList();
    prefs.setString('routines', jsonEncode(jsonList));
  }

  Future<void> deleteRoutine(int index) async {
    routines.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = routines.map((e) => e.toJson()).toList();
    prefs.setString('routines', jsonEncode(jsonList));
  }
}
