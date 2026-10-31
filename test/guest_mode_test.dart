// Test doubles never contact Firebase or change real member data.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counter_01/app_router.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/models/workout_record.dart';
import 'package:counter_01/repositories/auth_repository.dart';
import 'package:counter_01/repositories/guest_store.dart';
import 'package:counter_01/repositories/guest_record_repository.dart';
import 'package:counter_01/repositories/guest_migration.dart';
import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/repositories/pending_workout_store.dart';
import 'package:counter_01/repositories/user_settings_repository.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';

final record = WorkoutRecord(
  date: DateTime(2026, 10, 31, 12, 3, 4, 5, 6),
  routineId: 'guest-routine',
  routineTitle: '게스트 운동',
  totalReps: 10,
);
final routine = Routine(
  id: 'guest-routine',
  title: '게스트 루틴',
  categoryId: 'FREE',
  ttsEnabled: false,
);

void main() {
  late Directory directory;
  late GuestStore store;
  GuestStore reopen() => GuestStore(directory: () async => directory);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sporkle_guest_test_');
    store = reopen();
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('게스트 기록·메모·루틴·설정은 저장 후 재시작해도 남고 동일 ID는 하나다', () async {
    await store.setActive(true);
    await store.saveRecord(record);
    await store.saveRecord(record);
    await store.saveRoutine(routine);
    await store.updateSettings({'onboardingDone': true, 'restSeconds': 7});
    final restarted = reopen();
    expect(await restarted.restore(), isTrue);
    expect((await restarted.records()).single.toJson(), record.toJson());
    expect(
      workoutRecordKey((await restarted.records()).single),
      workoutRecordKey(record),
    );
    expect((await restarted.routines()).single.ttsEnabled, isFalse);
    expect((await restarted.settings())['restSeconds'], 7);
    await restarted.saveRecord(
      record.copyWith(kind: RecordKind.memo, memo: '수정한 메모'),
    );
    expect((await reopen().records()).single.memo, '수정한 메모');
  });

  test('완료 기록은 게스트에서 서버 없이 저장되고 RecordsVM 재생성 후 표시된다', () async {
    String? uid = GuestStore.uid;
    final remote = _Remote();
    RecordsViewModel vm(GuestStore local) => RecordsViewModel(
      GuestRecordRepository(remote, local, currentUid: () => uid),
      pendingWorkouts: PendingWorkoutStore(directory: () async => directory),
    );
    final first = vm(store)..bindAccount(uid);
    await first.addRecord(record, accountUid: uid);
    first.dispose();
    final restarted = vm(reopen())..bindAccount(uid);
    await _settle(restarted);
    expect(restarted.records.single.toJson(), record.toJson());
    expect(remote.saves, 0);
    restarted.dispose();
  });

  test('기존 계정 기록과 합치고 같은 ID의 계정 기록은 덮어쓰지 않는다', () async {
    await store.saveRecord(record);
    await store.saveRoutine(routine);
    final remote = _Remote();
    remote.data[workoutRecordKey(record)] = record.copyWith(
      routineTitle: '기존 계정에서 수정한 제목',
    );
    final other = record.copyWith(
      date: record.date.add(const Duration(days: 1)),
    );
    remote.data[workoutRecordKey(other)] = other;
    final migration = GuestMigration(
      store,
      writeRecord: (_, r) async {
        remote.data.putIfAbsent(workoutRecordKey(r), () => r);
      },
      writeRoutine: (_, r) async {},
    );
    await migration.retry('a', isCurrent: () => true);
    await migration.retry('a', isCurrent: () => true);
    expect(remote.data, hasLength(2));
    expect(
      remote.data[workoutRecordKey(record)]!.routineTitle,
      '기존 계정에서 수정한 제목',
    );
    expect(await store.records(), isEmpty);
    expect(await store.records(accountUid: 'a'), isEmpty);
    expect(await store.routines(accountUid: 'a'), isEmpty);
  });

  test('업로드 실패/재시작 후 원본은 같은 계정에만 남고 B 계정에는 옮기지 않는다', () async {
    await store.saveRecord(record);
    final fail = GuestMigration(
      store,
      writeRecord: (_, r) async {
        throw StateError('offline');
      },
      writeRoutine: (_, r) async {},
    );
    await expectLater(fail.retry('a', isCurrent: () => true), throwsStateError);
    final restarted = reopen();
    final destinations = <String>[];
    final migration = GuestMigration(
      restarted,
      writeRecord: (uid, r) async {
        destinations.add(uid);
      },
      writeRoutine: (_, r) async {},
    );
    await migration.retry('b', isCurrent: () => true);
    expect(destinations, isEmpty);
    expect(await restarted.records(accountUid: 'a'), hasLength(1));
    await migration.retry('a', isCurrent: () => true);
    expect(destinations, ['a']);
  });

  test('서버 반영 후 응답 유실이어도 재시작 재시도는 같은 문서만 사용한다', () async {
    await store.saveRecord(record);
    final keys = <String>{};
    var failOnce = true;
    Future<void> write(String uid, WorkoutRecord r) async {
      keys.add('$uid/${workoutRecordKey(r)}');
      if (failOnce) {
        failOnce = false;
        throw StateError('lost acknowledgement');
      }
    }

    await expectLater(
      GuestMigration(
        store,
        writeRecord: write,
        writeRoutine: (_, r) async {},
      ).retry('a', isCurrent: () => true),
      throwsStateError,
    );
    await GuestMigration(
      reopen(),
      writeRecord: write,
      writeRoutine: (_, r) async {},
    ).retry('a', isCurrent: () => true);
    expect(keys, hasLength(1));
    expect(await reopen().records(accountUid: 'a'), isEmpty);
  });

  test('계정 전환 중 이전 업로드는 새 계정으로 이어가지 않는다', () async {
    await store.saveRoutine(routine);
    await store.saveRecord(record);
    var current = true;
    final uploaded = <String>[];
    final migration = GuestMigration(
      store,
      writeRoutine: (uid, r) async {
        current = false;
      },
      writeRecord: (uid, r) async {
        uploaded.add(uid);
      },
    );
    await expectLater(
      migration.retry('a', isCurrent: () => current),
      throwsStateError,
    );
    expect(uploaded, isEmpty);
    expect(await store.records(accountUid: 'a'), hasLength(1));
    expect(await store.records(accountUid: 'b'), isEmpty);
  });

  test('VM에 병합 실패를 표시하고 재시도 후 재로딩해 중복 없이 보여준다', () async {
    await store.saveRecord(record);
    final remote = _Remote();
    var offline = true;
    final migration = GuestMigration(
      store,
      writeRoutine: (_, r) async {},
      writeRecord: (_, r) async {
        if (offline) throw StateError('offline');
        remote.data.putIfAbsent(workoutRecordKey(r), () => r);
      },
    );
    final vm = RecordsViewModel(
      GuestRecordRepository(remote, store, currentUid: () => 'a'),
      guestMigration: migration,
    )..bindAccount('a');
    await _settle(vm);
    expect(vm.recoveryFailed, isTrue);
    expect(vm.pendingCount, 1);
    expect(vm.records, hasLength(1));
    offline = false;
    await vm.retryPendingRecords();
    expect(vm.recoveryFailed, isFalse);
    expect(vm.pendingCount, 0);
    expect(vm.records, hasLength(1));
    vm.dispose();
  });

  test('손상된 게스트 파일을 빈 기록으로 덮어쓰지 않는다', () async {
    await File('${directory.path}/guest_v1.json').writeAsString('{damaged');
    await expectLater(store.saveRecord(record), throwsFormatException);
    expect(
      await File('${directory.path}/guest_v1.json').readAsString(),
      '{damaged',
    );
  });

  test('게스트 파일 작업 중 화면 트리가 해제돼도 해제된 VM을 알리지 않는다', () async {
    final gate = Completer<Directory>();
    final local = GuestStore(directory: () => gate.future);
    final repo = _AuthRepository();
    final auth = AuthViewModel(repo, guestStore: local);
    final starting = auth.continueAsGuest();
    auth.dispose();
    gate.complete(directory);
    await starting;
    expect(local.active, isTrue);
    expect(auth.isGuest, isFalse);
    await repo.changes.close();
  });

  test('탈퇴 전 전송을 중지하고 이미 진행한 쓰기가 끝날 때까지 기다린다', () async {
    await store.saveRecord(record);
    final started = Completer<void>();
    final release = Completer<void>();
    final migration = GuestMigration(
      store,
      writeRoutine: (_, r) async {},
      writeRecord: (_, r) async {
        started.complete();
        await release.future;
      },
    );
    final saving = migration.retry('a', isCurrent: () => true);
    final assertion = expectLater(saving, throwsStateError);
    await started.future;
    var drained = false;
    final pausing = migration.pause('a').then((_) => drained = true);
    await Future<void>.delayed(Duration.zero);
    expect(drained, isFalse);
    release.complete();
    await assertion;
    await pausing;
    expect(drained, isTrue);
    await expectLater(
      migration.retry('a', isCurrent: () => true),
      throwsStateError,
    );
    migration.resume('a');
    await migration.retry('a', isCurrent: () => true);
  });

  test('같은 게스트 UID로 돌아와도 이전 세션의 대기 쓰기는 새 게스트에 넣지 않는다', () async {
    final gate = Completer<Directory>();
    final local = GuestStore(directory: () => gate.future);
    var scope = 1;
    final restoring = local.restore();
    final repository = GuestRecordRepository(
      _Remote(),
      local,
      currentUid: () => GuestStore.uid,
      currentScope: () => scope,
    );
    final saving = repository.save(record, uid: GuestStore.uid);
    final assertion = expectLater(saving, throwsStateError);
    scope = 3;
    gate.complete(directory);
    await restoring;
    await assertion;
    expect(await local.records(), isEmpty);
  });

  test('병합 대기 원본을 표시한 뒤 서버 문서를 다시 읽으면 서버 수정 내용을 보존한다', () async {
    await store.saveRecord(record);
    final remote = _Remote();
    final migration = GuestMigration(
      store,
      writeRoutine: (_, r) async {},
      writeRecord: (_, r) async {
        throw StateError('offline');
      },
    );
    final vm = RecordsViewModel(
      GuestRecordRepository(remote, store, currentUid: () => 'a'),
      guestMigration: migration,
    )..bindAccount('a');
    await _settle(vm);
    remote.data[workoutRecordKey(record)] = record.copyWith(
      routineTitle: '서버에서 수정',
    );
    await vm.reload();
    expect(vm.records.single.routineTitle, '서버에서 수정');
    vm.dispose();
  });

  test('게스트 선택과 온보딩을 재시작 후 복원하고 회원 로그인과 구분한다', () async {
    final repo = _AuthRepository();
    final auth = AuthViewModel(
      repo,
      guestStore: store,
      settingsRepo: UserSettingsRepository(guestStore: store),
    );
    await auth.continueAsGuest();
    await auth.completeOnboarding(weeklyTarget: 3);
    expect(auth.isGuest, isTrue);
    expect(auth.signedIn, isFalse);
    expect(auth.canUseApp, isTrue);
    auth.dispose();
    final local = reopen();
    final restartedRepo = _AuthRepository();
    final restarted = AuthViewModel(
      restartedRepo,
      guestStore: local,
      settingsRepo: UserSettingsRepository(guestStore: local),
    );
    restartedRepo.changes.add(null);
    for (var i = 0; i < 100 && !restarted.authReady; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(restarted.isGuest, isTrue);
    expect(restarted.onboardingDone, isTrue);
    expect(restarted.weeklyTarget, 3);
    restarted.dispose();
    await repo.changes.close();
    await restartedRepo.changes.close();
  });

  test('게스트 루틴 생성·수정·즐겨찾기·TTS·삭제는 로컬에 지속된다', () async {
    final repo = _AuthRepository();
    final auth = AuthViewModel(
      repo,
      guestStore: store,
      settingsRepo: UserSettingsRepository(guestStore: store),
    );
    await auth.continueAsGuest();
    final vm = RoutinesViewModel(
      db: _Db(),
      auth: _FirebaseAuth(),
      guestStore: store,
      session: auth,
    )..bind();
    for (var i = 0; i < 100 && vm.isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    final id = await vm.createRoutine(title: '내 루틴');
    await vm.setTitle(id, '새 제목');
    await vm.toggleFavorite(id);
    await vm.setRoutineTts(id, false);
    final persisted = (await reopen().routines()).single;
    expect(persisted.title, '새 제목');
    expect(persisted.favorite, isTrue);
    expect(persisted.ttsEnabled, isFalse);
    await vm.deleteRoutines({id}, ownerUid: GuestStore.uid);
    expect(await reopen().routines(), isEmpty);
    vm.dispose();
    auth.dispose();
    await repo.changes.close();
  });

  test('게스트는 앱에 접근하고 설정에서 로그인 화면도 열 수 있다', () {
    expect(
      redirectForAuth(
        authReady: true,
        signedIn: true,
        isGuest: true,
        onboardingDone: true,
        location: '/home',
      ),
      isNull,
    );
    expect(
      redirectForAuth(
        authReady: true,
        signedIn: true,
        isGuest: true,
        onboardingDone: true,
        location: '/login',
      ),
      isNull,
    );
    expect(
      redirectForAuth(
        authReady: true,
        signedIn: false,
        onboardingDone: false,
        location: '/home',
      ),
      '/login',
    );
  });
}

Future<void> _settle(RecordsViewModel vm) async {
  for (var i = 0; i < 200 && (vm.isLoading || vm.recovering); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(vm.isLoading || vm.recovering, isFalse);
}

class _Remote implements RecordRepository {
  final data = <String, WorkoutRecord>{};
  int saves = 0;
  @override
  Future<List<WorkoutRecord>> loadAll({String? uid}) async =>
      data.values.toList();
  @override
  Future<void> save(WorkoutRecord r, {String? uid}) async {
    saves++;
    data[workoutRecordKey(r)] = r;
  }
}

class _AuthRepository extends Fake implements AuthRepository {
  final changes = StreamController<AppUser?>.broadcast();
  @override
  bool onboardingDone = false;
  @override
  Stream<AppUser?> userChanges() => changes.stream;
  @override
  AppUser? currentUser() => null;
}

class _Db extends Fake implements FirebaseFirestore {}

class _FirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}
