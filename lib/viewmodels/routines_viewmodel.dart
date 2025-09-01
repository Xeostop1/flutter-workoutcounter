import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';
import '../repositories/routine_repository.dart';

class RoutinesViewModel extends ChangeNotifier {
  final RoutineRepository _repo;
  RoutinesViewModel(this._repo);

  String order = '최근';
  Routine? selected;

  List<RoutineCategory> get categories => _repo.categories();
  List<Routine> get allRoutines => _repo.all();

  void toggleFavorite(String id) {
    for (final r in allRoutines) {
      if (r.id == id) { r.favorite = !r.favorite; break; }
    }
    notifyListeners();
  }

  void setOrder(String v) { order = v; notifyListeners(); }
  void select(Routine r) { selected = r; notifyListeners(); }
}
