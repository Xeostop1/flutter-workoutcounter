import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';

const _u = Uuid(); // **** 직접 uuid 인스턴스 사용

final lowerCategory = RoutineCategory(
  id: _u.v4(), // 카테고리는 슬러그 유지
  name: '하체',
  routines: [
    Routine(
      id: _u.v4(),
      title: '핵스쿼트',
      items: [
        Exercise(id: _u.v4(), name: '핵스쿼트', reps: 20, sets: 3, repSeconds: 2),
        Exercise(id: _u.v4(), name: '런지', reps: 20, sets: 3, repSeconds: 2),
      ],
    ),
    Routine(
      id: _u.v4(),
      title: '스쿼트',
      items: [
        Exercise(id: _u.v4(), name: '스쿼트', reps: 25, sets: 3, repSeconds: 2),
        Exercise(id: _u.v4(), name: '카프레이즈', reps: 30, sets: 3, repSeconds: 2),
      ],
    ),
    Routine(
      id: _u.v4(),
      title: '힙브릿지',
      items: [
        Exercise(id: _u.v4(), name: '힙브릿지', reps: 20, sets: 3, repSeconds: 2),
      ],
    ),
  ],
);

final categoriesSeed = [lowerCategory];
