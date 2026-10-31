import 'package:flutter_test/flutter_test.dart';

import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/record_repository.dart';

void main() {
  test('같은 기록을 수정하면 중복되지 않는다', () async {
    final repository = InMemoryRecordRepository();
    final record = WorkoutRecord.memo(
      date: DateTime(2026, 8, 15),
      title: '목요일 운동',
      memo: '홈트 진행',
    );

    await repository.save(record);
    await repository.save(record.copyWith(memo: '하체 운동 완료'));
    final restored = await repository.loadAll();

    expect(restored, hasLength(1));
    expect(restored.single.memo, '하체 운동 완료');
  });
}
