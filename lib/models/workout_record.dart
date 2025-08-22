import 'package:flutter/foundation.dart';

@immutable
class WorkoutRecord {
  final String id; // routineId + timestamp
  final String routineId;
  final String routineName;
  final DateTime date; // 완료 시각
  final int doneSets; // 완료 세트 수
  final int doneRepsTotal; // 전체 수행 횟수
  final int durationSec; // 총 소요 시간(초) - 과거 데이터 호환 위해 기본값 0 사용

  const WorkoutRecord({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.date,
    required this.doneSets,
    required this.doneRepsTotal,
    this.durationSec = 0, // ✅ 기본값 0
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'routineName': routineName,
    'date': date.toIso8601String(),
    'doneSets': doneSets,
    'doneRepsTotal': doneRepsTotal,
    'durationSec': durationSec,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) => WorkoutRecord(
    id: j['id'] as String,
    routineId: j['routineId'] as String,
    routineName: j['routineName'] as String,
    date: DateTime.parse(j['date'] as String),
    doneSets: _asInt(j['doneSets']), // ✅ 안전 변환
    doneRepsTotal: _asInt(j['doneRepsTotal']), // ✅ 안전 변환
    durationSec: _asInt(j['durationSec']), // ✅ 없으면 0
  );
}

/// 어떤 타입이 와도 int로 안전 변환 (null/double/string 케이스 포함)
int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
