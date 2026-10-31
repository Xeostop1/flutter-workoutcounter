import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/workout_record.dart';
import 'record_repository.dart';

class PendingWorkoutStore {
  PendingWorkoutStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  final Set<String> _deletedAccounts = {};
  Future<void> _operation = Future.value();

  Future<T> _run<T>(Future<T> Function() action) {
    final next = _operation.then((_) => action());
    _operation = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  String _encode(String value) => base64Url.encode(utf8.encode(value));

  Future<Directory> _accountDirectory(String uid) async {
    final root = await _directory();
    return Directory('${root.path}/pending_workouts_v1/${_encode(uid)}');
  }

  Future<List<WorkoutRecord>> load(String uid) => _run(() async {
    if (_deletedAccounts.contains(uid)) return [];
    final directory = await _accountDirectory(uid);
    if (!await directory.exists()) return [];
    final records = <WorkoutRecord>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is File && entry.path.endsWith('.json')) {
        final record = WorkoutRecord.fromJson(
          jsonDecode(await entry.readAsString()) as Map<String, dynamic>,
        );
        records.add(record.copyWith(date: record.date.toLocal()));
      }
    }
    return records;
  });

  Future<void> save(String uid, WorkoutRecord record) => _run(() async {
    if (_deletedAccounts.contains(uid)) {
      throw StateError('삭제된 계정에는 운동 기록을 저장할 수 없습니다.');
    }
    final directory = await _accountDirectory(uid);
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/${_encode(workoutRecordKey(record))}.json',
    );
    if (await file.exists()) return;

    // 서버 저장 전에 완성된 로컬 파일을 확보하고, 재시도 중에는 덮어쓰지 않는다.
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        ...record.toJson(),
        'date': record.date.toUtc().toIso8601String(),
      }),
      flush: true,
    );
    await temporary.rename(file.path);
  });

  Future<void> remove(String uid, WorkoutRecord record) => _run(() async {
    final directory = await _accountDirectory(uid);
    final file = File(
      '${directory.path}/${_encode(workoutRecordKey(record))}.json',
    );
    if (await file.exists()) await file.delete();
  });

  Future<void> clear(String uid) {
    _deletedAccounts.add(uid);
    return _run(() async {
      final directory = await _accountDirectory(uid);
      if (await directory.exists()) await directory.delete(recursive: true);
    });
  }
}
