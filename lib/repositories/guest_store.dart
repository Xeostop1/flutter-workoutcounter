import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/routine.dart';
import '../models/workout_record.dart';
import 'record_repository.dart';

/// Device-only data. Account-bound transfers survive a restart and cannot be
/// claimed by a second account after a partially completed upload.
class GuestStore {
  GuestStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const uid = 'local_guest_v1';
  final Future<Directory> Function() _directory;
  Future<void> _operation = Future.value();
  Map<String, dynamic>? _state;
  bool get active => _state?['active'] == true;

  Future<T> _run<T>(Future<T> Function() action) {
    final next = _operation.then((_) => action());
    _operation = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<File> _file() async =>
      File('${(await _directory()).path}/guest_v1.json');

  Future<Map<String, dynamic>> _read() async {
    if (_state != null) return _state!;
    final file = await _file();
    if (!await file.exists()) return _state = {};
    // A damaged file must not silently become an empty guest account.
    final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _state = value;
  }

  Future<void> _write(Map<String, dynamic> next) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(next), flush: true);
    await temporary.rename(file.path);
    _state = next;
  }

  Future<void> _edit(
    void Function(Map<String, dynamic>) change, {
    bool Function()? isCurrent,
  }) => _run(() async {
    final next = jsonDecode(jsonEncode(await _read())) as Map<String, dynamic>;
    if (isCurrent != null && !isCurrent()) throw StateError('계정이 변경되었습니다.');
    change(next);
    await _write(next);
  });

  Future<bool> restore() => _run(() async {
    await _read();
    return active;
  });
  Future<void> setActive(bool value) => _edit((data) => data['active'] = value);

  Future<Map<String, dynamic>> settings() => _run(
    () async =>
        Map<String, dynamic>.from((await _read())['settings'] as Map? ?? {}),
  );
  Future<void> updateSettings(Map<String, Object?> changes) => _edit((data) {
    data['settings'] = {...?data['settings'] as Map?, ...changes};
  });

  Future<List<WorkoutRecord>> records({String? accountUid}) => _run(() async {
    final data = await _read();
    final source = accountUid == null
        ? data
        : (data['imports'] as Map?)?[accountUid] as Map? ?? {};
    return ((source['records'] as Map?) ?? {}).values.map((value) {
      final record = WorkoutRecord.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
      return record.copyWith(date: record.date.toLocal());
    }).toList();
  });

  Future<void> saveRecord(WorkoutRecord record, {bool Function()? isCurrent}) =>
      _edit((data) {
        final records = Map<String, dynamic>.from(
          data['records'] as Map? ?? {},
        );
        records[workoutRecordKey(record)] = {
          ...record.toJson(),
          'date': record.date.toUtc().toIso8601String(),
        };
        data['records'] = records;
      }, isCurrent: isCurrent);

  Future<List<Routine>> routines({String? accountUid}) => _run(() async {
    final data = await _read();
    final source = accountUid == null
        ? data
        : (data['imports'] as Map?)?[accountUid] as Map? ?? {};
    return ((source['routines'] as Map?) ?? {}).values
        .map(
          (value) => Routine.fromMap(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  });

  Future<void> saveRoutine(Routine routine, {bool Function()? isCurrent}) =>
      _edit((data) {
        final routines = Map<String, dynamic>.from(
          data['routines'] as Map? ?? {},
        );
        routines[routine.id] = routine.toMap();
        data['routines'] = routines;
      }, isCurrent: isCurrent);

  Future<void> deleteRoutines(
    Set<String> ids, {
    required bool Function() isCurrent,
  }) => _edit((data) {
    final routines = Map<String, dynamic>.from(data['routines'] as Map? ?? {});
    for (final id in ids) {
      routines.remove(id);
    }
    data['routines'] = routines;
  }, isCurrent: isCurrent);

  Future<void> claim(String accountUid, {required bool Function() isCurrent}) =>
      _edit((data) {
        if (accountUid == uid) throw ArgumentError('실제 로그인 계정이 필요합니다.');
        final imports = Map<String, dynamic>.from(
          data['imports'] as Map? ?? {},
        );
        final previous = Map<String, dynamic>.from(
          imports[accountUid] as Map? ?? {},
        );
        for (final kind in ['records', 'routines']) {
          previous[kind] = {...?previous[kind] as Map?, ...?data[kind] as Map?};
          data[kind] = <String, dynamic>{};
        }
        imports[accountUid] = previous;
        data['imports'] = imports;
        data['active'] = false;
      }, isCurrent: isCurrent);

  Future<void> acknowledge(String accountUid, String kind, String key) =>
      _edit((data) {
        final imports = data['imports'] as Map?;
        final transfer = imports?[accountUid] as Map?;
        (transfer?[kind] as Map?)?.remove(key);
      });

  Future<void> forgetAccount(String accountUid) => _edit((data) {
    (data['imports'] as Map?)?.remove(accountUid);
  });
}
