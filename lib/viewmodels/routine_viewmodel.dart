import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../repositories/routine_repository.dart';

class RoutineViewModel extends ChangeNotifier {
  final RoutineRepository repo;
  List<Routine> routines = [];
  String sort = 'recent'; // recent | name | favorite

  RoutineViewModel(this.repo);

  Future<void> load() async {
    routines = await repo.load();
    notifyListeners();
  }

  Future<void> upsert(Routine item) async {
    final idx = routines.indexWhere((e) => e.id == item.id);
    if (idx == -1) {
      routines = [...routines, item];
    } else {
      routines[idx] = item;
    }
    await repo.saveAll(routines);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final idx = routines.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    routines[idx] = routines[idx].copyWith(favorite: !routines[idx].favorite);
    await repo.saveAll(routines);
    notifyListeners();
  }

  List<Routine> get sorted {
    final list = [...routines];
    switch (sort) {
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'favorite':
        list.sort((a, b) => (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0));
        break;
      default:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }
}
