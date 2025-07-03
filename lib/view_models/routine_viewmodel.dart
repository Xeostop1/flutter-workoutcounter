import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class RoutineViewModel extends ChangeNotifier {
  List<Routine> _routines = [];

  List<Routine> get routines => _routines;

  Future<void> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('saved_routines');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _routines = jsonList.map((item) => Routine.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> saveRoutine(Routine routine) async {
    _routines.add(routine);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteRoutine(int index) async {
    _routines.removeAt(index);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
    json.encode(_routines.map((routine) => routine.toJson()).toList());
    await prefs.setString('saved_routines', jsonString);
  }
}
