import '../data/categories_seed.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';

abstract class RoutineRepository {
  List<RoutineCategory> categories();
  List<Routine> all();
}

class SeedRoutineRepository implements RoutineRepository {
  final List<RoutineCategory> _cats = [...categoriesSeed];
  @override
  List<RoutineCategory> categories() => _cats;
  @override
  List<Routine> all() => _cats.expand((c) => c.routines).toList();
}
