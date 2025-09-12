import 'package:flutter/foundation.dart';
import '../repositories/streak_repository.dart';

class StreakViewModel extends ChangeNotifier {
  StreakViewModel(this._repo);

  final StreakRepository _repo;

  int _day = 1;
  int get day => _day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 앱 시작 시 한 번 호출: 오늘 실행 여부를 반영해 day 증가/리셋
  Future<void> ensureTodayUpdated() async {
    final today = _dateOnly(DateTime.now());

    final last = await _repo.getLastOpen();
    final savedDay = await _repo.getDay() ?? 0;

    if (last == null) {
      // 처음 실행
      _day = 1;
    } else {
      final diff = today.difference(_dateOnly(last)).inDays;
      if (diff <= 0) {
        // 오늘 이미 켰음(중복 실행) → 기존 값 유지(최소 1)
        _day = savedDay > 0 ? savedDay : 1;
      } else if (diff == 1) {
        // 어제도 켰음 → 연속 +1
        _day = (savedDay > 0 ? savedDay : 1) + 1;
      } else {
        // 하루 이상 쉬었음 → 1부터 재시작
        _day = 1;
      }
    }

    // 오늘 날짜와 계산된 Day 저장
    await _repo.save(today, _day);
    notifyListeners();
  }
}
