import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_record.dart';
import '../repositories/record_repository.dart';
import '../repositories/pending_workout_store.dart';
import '../repositories/guest_migration.dart';
import '../repositories/guest_store.dart';

class RecordsViewModel extends ChangeNotifier {
  RecordsViewModel(
    this._repo, {
    PendingWorkoutStore? pendingWorkouts,
    GuestMigration? guestMigration,
  }) : _pendingWorkouts = pendingWorkouts,
       _guestMigration = guestMigration;

  final RecordRepository _repo;
  final PendingWorkoutStore? _pendingWorkouts;
  final GuestMigration? _guestMigration;
  final Map<String, Future<void>> _recordSaves = {};
  final Set<String> _pendingKeys = {};
  Set<String>? _writesDuringLoad;
  int _accountGeneration = 0;
  bool _recovering = false;
  bool _recoveryFailed = false;
  bool _disposed = false;
  String? get accountUid => _accountUid;
  int get pendingCount => _pendingKeys.length;
  bool get recovering => _recovering;
  bool get recoveryFailed => _recoveryFailed;
  final List<WorkoutRecord> _records = [];
  String? _accountUid;
  int _loadGeneration = 0;
  bool _isLoading = false;
  Object? _loadError;
  int get totalCount => _records.length;
  List<WorkoutRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;

  DateTime _selectedDay = _strip(DateTime.now());
  DateTime _focusedDay = _strip(DateTime.now());

  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;

  // 기존 화면 호환용
  DateTime get selectedDate => _selectedDay;

  void bindAccount(String? uid) {
    if (_accountUid == uid) return;

    _accountUid = uid;
    _accountGeneration++;
    final generation = ++_loadGeneration;
    _records.clear();
    _writesDuringLoad = null;
    _isLoading = uid != null;
    _loadError = null;
    _pendingKeys.clear();
    _recovering = false;
    _recoveryFailed = false;
    notifyListeners();

    if (uid != null) unawaited(_load(uid, generation));
    if (uid != null &&
        uid != GuestStore.uid &&
        (_pendingWorkouts != null || _guestMigration != null)) {
      unawaited(retryPendingRecords());
    }
  }

  bool _sameAccount(String? uid, int generation) =>
      !_disposed && _accountUid == uid && _accountGeneration == generation;

  Future<void> retryPendingRecords() async {
    final store = _pendingWorkouts;
    final uid = _accountUid;
    if (uid == null || uid == GuestStore.uid || _recovering) return;
    if (store == null && _guestMigration == null) return;
    final generation = _accountGeneration;
    _recovering = true;
    _recoveryFailed = false;
    notifyListeners();
    try {
      final migration = _guestMigration;
      if (migration != null) {
        try {
          await migration.retry(
            uid,
            isCurrent: () => _sameAccount(uid, generation),
          );
        } catch (_) {
          if (_sameAccount(uid, generation)) _recoveryFailed = true;
        }
        if (!_sameAccount(uid, generation)) return;
        _pendingKeys.removeWhere((key) => key.startsWith('guest/'));
        _pendingKeys.addAll(
          (await migration.store.records(
            accountUid: uid,
          )).map((r) => 'guest/${workoutRecordKey(r)}'),
        );
        _pendingKeys.addAll(
          (await migration.store.routines(
            accountUid: uid,
          )).map((r) => 'guest/routine/${r.id}'),
        );
      }
      final records = await store?.load(uid) ?? <WorkoutRecord>[];
      if (!_sameAccount(uid, generation)) return;
      _pendingKeys.addAll(records.map(workoutRecordKey));
      notifyListeners();
      for (final record in records) {
        if (!_sameAccount(uid, generation)) return;
        try {
          await addRecord(record, accountUid: uid);
        } catch (_) {
          if (_sameAccount(uid, generation)) _recoveryFailed = true;
        }
      }
    } catch (_) {
      if (_sameAccount(uid, generation)) _recoveryFailed = true;
    } finally {
      if (_sameAccount(uid, generation)) {
        _recovering = false;
        notifyListeners();
        if (_guestMigration != null) {
          _isLoading = true;
          await _load(uid, ++_loadGeneration);
        }
      }
    }
  }

  Future<void> _load(String uid, int generation) async {
    final localWrites = <String>{};
    _writesDuringLoad = localWrites;
    try {
      final all = await _repo.loadAll(uid: uid);
      if (_loadGeneration != generation || _accountUid != uid) return;

      final merged = <String, WorkoutRecord>{
        for (final record in _records) workoutRecordKey(record): record,
        for (final record in all) workoutRecordKey(record): record,
        for (final record in _records)
          if (localWrites.contains(workoutRecordKey(record)))
            workoutRecordKey(record): record,
      };
      _records
        ..clear()
        ..addAll(merged.values);
      _isLoading = false;
      _loadError = null;
      _writesDuringLoad = null;
      notifyListeners();
    } catch (error) {
      if (_loadGeneration != generation || _accountUid != uid) return;
      _isLoading = false;
      _loadError = error;
      _writesDuringLoad = null;
      notifyListeners();
      if (kDebugMode) print('RecordsViewModel: failed to load records: $error');
    }
  }

  Future<void> reload() async {
    final uid = _accountUid;
    if (uid == null || _isLoading) return;

    final generation = ++_loadGeneration;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    await _load(uid, generation);
  }

  void selectDay(DateTime day) {
    _selectedDay = _strip(day);
    _focusedDay = _selectedDay;
    notifyListeners();
  }

  List<WorkoutRecord> recordsOfSelected() => recordsOn(_selectedDay);

  Future<void> addRecord(WorkoutRecord record, {String? accountUid}) async {
    final uid = accountUid ?? _accountUid;
    if (uid != _accountUid || (_pendingWorkouts != null && uid == null)) {
      throw StateError('운동 기록의 로그인 계정을 확인해주세요.');
    }
    final generation = _accountGeneration;
    final key = '$uid/${workoutRecordKey(record)}';
    await _recordSaves.putIfAbsent(key, () {
      final saving = _saveRecord(record, uid, generation);
      return saving.whenComplete(() {
        _recordSaves.remove(key);
      });
    });
    if (!_sameAccount(uid, generation)) return;
    final recordKey = workoutRecordKey(record);
    _writesDuringLoad?.add(recordKey);
    _pendingKeys.remove(recordKey);
    final index = _records.indexWhere(
      (item) => workoutRecordKey(item) == recordKey,
    );
    if (index == -1) {
      _records.add(record);
    } else {
      _records[index] = record;
    }
    if (_pendingKeys.isEmpty && _guestMigration == null) {
      _recoveryFailed = false;
    }
    notifyListeners();
  }

  Future<void> _saveRecord(
    WorkoutRecord record,
    String? uid,
    int generation,
  ) async {
    final key = workoutRecordKey(record);
    final store = uid == GuestStore.uid ? null : _pendingWorkouts;
    if (store != null) {
      await store.save(uid!, record);
      if (!_sameAccount(uid, generation)) {
        throw StateError('운동 기록 저장 중 로그인 계정이 변경되었습니다.');
      }
      _pendingKeys.add(key);
      notifyListeners();
    }
    await _repo.save(record, uid: uid);
    if (store != null) await store.remove(uid!, record);
  }

  Future<void> addManualRecord({
    required DateTime date,
    required String title,
    String? memo,
  }) async {
    final accountUid = _accountUid;
    final record = WorkoutRecord.memo(date: date, title: title, memo: memo);
    await _repo.save(record, uid: accountUid);
    if (_accountUid != accountUid) return;
    _writesDuringLoad?.add(workoutRecordKey(record));
    if (_records.any(
      (current) => workoutRecordKey(current) == workoutRecordKey(record),
    )) {
      return;
    }
    _records.add(record);
    notifyListeners();
  }

  Future<void> updateManualRecord(
    WorkoutRecord target, {
    required String title,
    String? memo,
  }) async {
    final accountUid = _accountUid;
    final index = _findManualRecordIndex(target);
    if (index == -1) return;

    final updated = _records[index].copyWith(
      routineTitle: title,
      memo: memo,
      kind: RecordKind.memo,
      routineId: WorkoutRecord.manualRoutineId,
      totalReps: 0,
    );

    await _repo.save(updated, uid: accountUid);
    if (_accountUid != accountUid) return;
    _writesDuringLoad?.add(workoutRecordKey(updated));
    final currentIndex = _findManualRecordIndex(target);
    if (currentIndex == -1) return;
    _records[currentIndex] = updated;
    notifyListeners();
  }

  Iterable<DateTime> allDays() sync* {
    final seen = <String>{};
    for (final record in _records) {
      final day = _strip(record.date);
      final key = '${day.year}-${day.month}-${day.day}';
      if (seen.add(key)) yield day;
    }
  }

  bool hasAnyOn(DateTime day) =>
      _records.any((record) => _sameDay(record.date, day));

  int workoutsThisWeek([DateTime? at]) {
    final today = _strip(at ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));

    return _records.where((record) {
      return record.kind == RecordKind.workout &&
          record.totalReps > 0 &&
          !record.date.isBefore(monday) &&
          record.date.isBefore(nextMonday);
    }).length;
  }

  List<WorkoutRecord> recordsOn(DateTime day) {
    return _records.where((record) => _sameDay(record.date, day)).toList();
  }

  int _findManualRecordIndex(WorkoutRecord target) {
    final sameInstanceIndex = _records.indexOf(target);
    if (sameInstanceIndex != -1) return sameInstanceIndex;

    return _records.indexWhere((record) {
      return _sameDay(record.date, target.date) &&
          record.kind == RecordKind.memo &&
          record.routineId == WorkoutRecord.manualRoutineId &&
          record.routineTitle == target.routineTitle &&
          (record.memo ?? '') == (target.memo ?? '');
    });
  }

  static DateTime _strip(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _disposed = true;
    _accountGeneration++;
    _loadGeneration++;
    super.dispose();
  }
}
