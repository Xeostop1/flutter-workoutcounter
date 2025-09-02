import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';

const _u = Uuid();

// 카테고리 UUID
final String _lowerCatId = _u.v4();

// 하체 카테고리의 루틴들 (모두 categoryId = _lowerCatId)
final List<Routine> _lowerRoutines = [
  Routine(
    id: _u.v4(),
    title: '핵스쿼트',
    categoryId: _lowerCatId,
    items: [
      Exercise(id: _u.v4(), name: '핵스쿼트', reps: 20, sets: 3, repSeconds: 2),
      Exercise(id: _u.v4(), name: '런지',     reps: 20, sets: 3, repSeconds: 2),
    ],
  ),
  Routine(
    id: _u.v4(),
    title: '스쿼트',
    categoryId: _lowerCatId,
    items: [
      Exercise(id: _u.v4(), name: '스쿼트',   reps: 25, sets: 3, repSeconds: 2),
      Exercise(id: _u.v4(), name: '카프레이즈', reps: 30, sets: 3, repSeconds: 2),
    ],
  ),
  Routine(
    id: _u.v4(),
    title: '힙브릿지',
    categoryId: _lowerCatId,
    items: [
      Exercise(id: _u.v4(), name: '힙브릿지', reps: 20, sets: 3, repSeconds: 2),
    ],
  ),
];

// 카테고리(이제 code 없음)
final lowerCategory = RoutineCategory(
  id: _lowerCatId,  // ✅ UUID
  name: '하체',
  routines: _lowerRoutines,
);

// 최종 시드
final categoriesSeed = [lowerCategory];
