import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_category.dart';
import '../data/routine_firestore.dart';
import '../repositories/guest_store.dart';
import 'auth_viewmodel.dart';

/// 루틴 정렬 옵션
enum RoutineOrder {
  recent, // 최근 수정순(기본)
  titleAsc, // 제목 오름차순
  titleDesc, // 제목 내림차순
  favoriteFirst, // 즐겨찾기 먼저
}

/// 루틴/카테고리 상태
class RoutinesViewModel extends ChangeNotifier {
  bool _favOnly = false;
  bool get favOnly => _favOnly;

  void setFavOnly(bool v) {
    if (_favOnly == v) return;
    _favOnly = v;
    notifyListeners();
  }

  void toggleFavOnly() => setFavOnly(!_favOnly);

  List<Routine> get filteredItems =>
      _favOnly ? items.where((r) => r.favorite).toList() : items;

  RoutinesViewModel({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    GuestStore? guestStore,
    AuthViewModel? session,
  }) : _db = db ?? FirebaseFirestore.instance,
       _guests = guestStore,
       _session = session,
       _auth = auth ?? FirebaseAuth.instance;
  final GuestStore? _guests;
  final AuthViewModel? _session;
  String? _boundUid;
  List<Routine> _pendingGuestRoutines = [];
  int _snapshotGeneration = 0;
  bool get _isGuest => _guests != null && _uid == GuestStore.uid;

  // Firestore, Auth
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    if (_session != null) {
      final sessionUid = _session.dataUid;
      if (sessionUid == null) throw StateError('운동 데이터를 저장할 계정이 없습니다.');
      return sessionUid;
    }
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('로그인 필요: FirebaseAuth.currentUser가 null 입니다.');
    }
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _colOf(String uid) =>
      _db.collection('users').doc(uid).collection('routines');

  CollectionReference<Map<String, dynamic>> get _col => _colOf(_uid);

  // 메모리 캐시
  List<RoutineCategory> categories = [];
  List<Routine> allRoutines = [];
  bool _isLoading = false;
  Object? _loadError;

  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;

  // 선택된 루틴
  String? _selectedRoutineId;
  String? get selectedRoutineId => _selectedRoutineId;

  Routine? get selected =>
      _selectedRoutineId == null ? null : getById(_selectedRoutineId!);

  void selectRoutine(String id) {
    if (_selectedRoutineId == id) return;
    _selectedRoutineId = id;
    notifyListeners();
  }

  /// 선택된 루틴 해제
  void clearSelectedRoutine() {
    if (_selectedRoutineId == null) return;
    _selectedRoutineId = null;
    notifyListeners();
  }

  Routine? getById(String id) {
    try {
      return allRoutines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 읽기 전용 전체 목록
  List<Routine> get items => List.unmodifiable(allRoutines);

  // 선택된 카테고리(UUID)
  String? selectedCategoryId;

  // 정렬 상태
  RoutineOrder _order = RoutineOrder.recent;
  RoutineOrder get order => _order;

  void setOrder(RoutineOrder newOrder) {
    if (_order == newOrder) return;
    _order = newOrder;
    // 정렬 기준 변경 알림
    notifyListeners();
  }

  // 실시간 바인딩
  StreamSubscription? _sub; // routines 컬렉션 구독
  StreamSubscription<User?>? _authSub; // auth 변화 구독
  int _bindGeneration = 0;

  /// Firestore와 실시간 동기화 시작
  /// - 로그인 전: 캐시 비움
  /// - 로그인 후: 해당 uid 경로로 재구독
  void bind() {
    _bindGeneration++;
    _sub?.cancel();
    _sub = null;
    // 이미 켜져 있으면 재설치
    _authSub?.cancel();
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    if (_session != null) {
      _session.removeListener(_onSessionChanged);
      _session.addListener(_onSessionChanged);
      _bindForUid(_session.dataUid);
      return;
    }
    _authSub = _auth.userChanges().listen((u) => _bindForUid(u?.uid));
  }

  void _onSessionChanged() {
    if (_boundUid != _session?.dataUid) _bindForUid(_session?.dataUid);
  }

  void _bindForUid(String? uid) {
    _boundUid = uid;
    final generation = ++_bindGeneration;
    // 기존 컬렉션 구독 해제
    _sub?.cancel();
    _sub = null;

    // 캐시 초기화 후 알림
    allRoutines = [];
    _pendingGuestRoutines = [];
    _selectedRoutineId = null;
    _isLoading = uid != null;
    _loadError = null;
    notifyListeners();

    if (uid == null) {
      if (kDebugMode) print('[RoutinesVM] bind: user=null (로그인 전)');
      return; // 로그인 되면 자동으로 재호출됨
    }

    if (uid == GuestStore.uid && _guests != null) {
      unawaited(_loadGuest(generation));
      return;
    }
    if (_guests != null) unawaited(_loadPendingRoutines(uid, generation));

    _sub = _colOf(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (qs) {
            if (generation != _bindGeneration) return;
            if (_guests != null) {
              unawaited(
                _applyCloudRoutines(
                  uid,
                  generation,
                  ++_snapshotGeneration,
                  qs.docs.map(RoutineFirestore.fromDoc).toList(),
                ),
              );
              return;
            }
            allRoutines = {
              for (final r in _pendingGuestRoutines) r.id: r,
              for (final r in qs.docs.map(RoutineFirestore.fromDoc)) r.id: r,
            }.values.toList();
            _isLoading = false;
            _loadError = null;

            // 선택 카테고리 기본값(최초 1회)
            selectedCategoryId ??= categories.isNotEmpty
                ? categories.first.id
                : null;

            notifyListeners();
          },
          onError: (e, st) {
            if (generation != _bindGeneration) return;
            _isLoading = false;
            _loadError = e;
            notifyListeners();
            if (kDebugMode) {
              print('RoutinesViewModel.bind stream error: $e');
            }
          },
        );
  }

  Future<void> _loadGuest(int generation) async {
    try {
      final routines = await _guests!.routines();
      if (generation != _bindGeneration) return;
      allRoutines = routines;
      _loadError = null;
    } catch (error) {
      if (generation != _bindGeneration) return;
      _loadError = error;
    }
    if (generation != _bindGeneration) return;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPendingRoutines(String uid, int generation) async {
    try {
      final pending = await _guests!.routines(accountUid: uid);
      if (generation != _bindGeneration) return;
      _pendingGuestRoutines = pending;
      allRoutines = {
        for (final r in pending) r.id: r,
        for (final r in allRoutines) r.id: r,
      }.values.toList();
      if (pending.isNotEmpty) _isLoading = false;
      notifyListeners();
    } catch (_) {
      // Records recovery exposes and retries the shared local migration failure.
    }
  }

  Future<void> _applyCloudRoutines(
    String uid,
    int generation,
    int snapshot,
    List<Routine> cloud,
  ) async {
    var pending = <Routine>[];
    try {
      pending = await _guests!.routines(accountUid: uid);
    } catch (_) {
      /* The shared recovery banner retains the local read failure. */
    }
    if (generation != _bindGeneration || snapshot != _snapshotGeneration) {
      return;
    }
    _pendingGuestRoutines = pending;
    allRoutines = {
      for (final r in pending) r.id: r,
      for (final r in cloud) r.id: r,
    }.values.toList();
    _isLoading = false;
    _loadError = null;
    notifyListeners();
  }

  void retryLoad() => bind();

  /// Firestore/Auth 구독 해제
  @override
  void dispose() {
    _bindGeneration++;
    _sub?.cancel();
    _authSub?.cancel();
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// 카테고리 시드 로드
  void loadSeed({required List<RoutineCategory> cats}) {
    categories = cats;
    selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
    notifyListeners();
  }

  // 표시용 유틸

  String categoryNameById(String id) {
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return '기타';
  }

  void selectCategory(String id) {
    if (selectedCategoryId == id) return;
    selectedCategoryId = id;
    notifyListeners();
  }

  // 카테고리 내 루틴(정렬 적용 안함)
  List<Routine> routinesByCategoryId(String categoryId) {
    return allRoutines.where((r) => r.categoryId == categoryId).toList();
  }

  // 카테고리 내 루틴(정렬 적용)
  List<Routine> routinesByCategoryIdOrdered(String categoryId) {
    final list = routinesByCategoryId(categoryId);

    switch (_order) {
      case RoutineOrder.recent:
        // Firestore 쿼리에서 updatedAt desc로 받으므로 그대로 반환
        return List<Routine>.from(list);

      case RoutineOrder.titleAsc:
        return List<Routine>.from(list)
          ..sort((a, b) => a.title.compareTo(b.title));

      case RoutineOrder.titleDesc:
        return List<Routine>.from(list)
          ..sort((a, b) => b.title.compareTo(a.title));

      case RoutineOrder.favoriteFirst:
        return List<Routine>.from(list)..sort((a, b) {
          // 문서의 favorite 필드 사용 (true 우선)
          final af = a.favorite ? 1 : 0;
          final bf = b.favorite ? 1 : 0;
          final favCmp = bf.compareTo(af);
          return favCmp != 0 ? favCmp : a.title.compareTo(b.title);
        });
    }
  }

  // StreamBuilder용 스트림
  Stream<List<Routine>> routinesStream() {
    if (_session?.isGuest == true) return Stream.value(items);
    final u = _auth.currentUser;
    if (u == null) return const Stream.empty();
    return _colOf(u.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(RoutineFirestore.fromDoc).toList());
  }

  // 쓰기 API

  /// 새 루틴 “초안”을 만들고 ID 반환 → 화면에서 이 ID로 편집 페이지 푸시
  Future<String> createDraft({String? title, String? categoryId}) async {
    return createRoutine(
      title: title?.trim().isNotEmpty == true ? title! : '새 루틴',
      categoryId: categoryId,
      isDraft: true,
    );
  }

  Future<void> _updateFields(String id, Map<String, dynamic> changes) async {
    if (!_isGuest) {
      await _col.doc(id).update(changes);
      return;
    }
    final routine = getById(id);
    if (routine == null) return;
    final updated = Routine.fromMap({
      ...routine.toMap(),
      ...changes,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final generation = _bindGeneration;
    await _guests!.saveRoutine(
      updated,
      isCurrent: () =>
          generation == _bindGeneration && _session?.isGuest == true,
    );
    if (generation != _bindGeneration) return;
    _updateInMemoryRoutine(updated);
    notifyListeners();
  }

  /// 제목 변경
  Future<void> setTitle(String routineId, String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    await _updateFields(routineId, {
      'title': t,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String routineId) async {
    final r = getById(routineId);
    if (r == null) return;
    await _updateFields(routineId, {
      'favorite': !r.favorite,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool isFavorite(String routineId) {
    final r = getById(routineId);
    return r?.favorite ?? false;
  }

  /// 운동 추가
  Future<void> addExercise(String routineId, Exercise ex) async {
    final r = getById(routineId);
    if (r == null) return;
    final updated = r.copyWith(items: [...r.items, ex]);
    await _updateFields(routineId, RoutineFirestore.toUpdateMap(updated));
  }

  /// 운동 삭제
  Future<void> removeExercise(String routineId, String exerciseId) async {
    final r = getById(routineId);
    if (r == null) return;
    final updated = r.copyWith(
      items: r.items.where((e) => e.id != exerciseId).toList(),
    );
    await _updateFields(routineId, RoutineFirestore.toUpdateMap(updated));
  }

  /// 루틴 삭제
  Future<void> deleteRoutine(String routineId) async {
    if (_isGuest) {
      await deleteRoutines({routineId}, ownerUid: _uid);
      return;
    }
    await _col.doc(routineId).delete();
    if (_selectedRoutineId == routineId) {
      _selectedRoutineId = null;
      notifyListeners();
    }
  }

  String get deletionAccountId => _uid;

  /// 확인창에 표시한 ID만, 확인 당시 계정에서 삭제한다.
  Future<void> deleteRoutines(
    Set<String> ids, {
    required String ownerUid,
  }) async {
    final generation = _bindGeneration;
    final targets = ids.toList(growable: false);
    if (_isGuest) {
      await _guests!.deleteRoutines(
        ids,
        isCurrent: () => _uid == ownerUid && generation == _bindGeneration,
      );
      if (generation != _bindGeneration) return;
      allRoutines = allRoutines.where((r) => !ids.contains(r.id)).toList();
      if (ids.contains(_selectedRoutineId)) _selectedRoutineId = null;
      notifyListeners();
      return;
    }
    for (var start = 0; start < targets.length; start += 400) {
      if (_uid != ownerUid || generation != _bindGeneration) {
        throw StateError('계정이 변경되었습니다.');
      }
      final batch = _db.batch();
      final chunk = targets.skip(start).take(400).toSet();
      for (final id in chunk) {
        if (id.isEmpty || id.contains('/')) throw ArgumentError('잘못된 루틴 ID');
        batch.delete(_colOf(ownerUid).doc(id));
      }
      await batch.commit();
      if (_uid != ownerUid || generation != _bindGeneration) {
        throw StateError('계정이 변경되었습니다.');
      }
      allRoutines = allRoutines.where((r) => !chunk.contains(r.id)).toList();
      if (chunk.contains(_selectedRoutineId)) _selectedRoutineId = null;
      notifyListeners();
    }
  }

  /// 새 루틴 생성
  Future<String> createRoutine({
    required String title,
    String? categoryId,
    List<Exercise> items = const [],
    bool favorite = false,
    bool archived = false,
    bool isDraft = false, // 생성 즉시 사용이니 기본 false
  }) async {
    final id = _isGuest ? 'guest_${const Uuid().v4()}' : _col.doc().id;
    final owner = _uid;
    final generation = _bindGeneration;
    final cid =
        categoryId ??
        selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : Routine.freeCategoryId);

    final r = Routine(
      id: id,
      title: title.trim().isEmpty ? '제목 없는 루틴' : title.trim(),
      categoryId: cid,
      items: items,
      ownerUid: owner,
      favorite: favorite,
      archived: archived,
      isDraft: isDraft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isGuest) {
      await _guests!.saveRoutine(
        r,
        isCurrent: () =>
            generation == _bindGeneration && _session?.isGuest == true,
      );
      if (generation == _bindGeneration) {
        allRoutines.add(r);
        notifyListeners();
      }
    } else {
      await _colOf(
        owner,
      ).doc(id).set(RoutineFirestore.toCreateMap(r, ownerUid: owner));
    }
    return id;
  }

  Future<void> setExercisesOrder(
    String routineId,
    List<Exercise> newOrder,
  ) async {
    final r = getById(routineId);
    if (r == null) return;

    final updated = r.copyWith(items: newOrder);
    await _updateFields(routineId, RoutineFirestore.toUpdateMap(updated));
  }

  Future<void> updateRoutine(
    String routineId, {
    required String title,
    required List<Exercise> items,
  }) async {
    final routine = getById(routineId);
    if (routine == null) return;
    final updated = routine.copyWith(
      title: title.trim(),
      items: List.unmodifiable(items),
      updatedAt: DateTime.now(),
    );
    await _updateFields(routineId, RoutineFirestore.toUpdateMap(updated));
  }

  // 루틴별 TTS 설정

  /// 메모리 캐시에서 TTS 사용 여부 반환
  bool ttsEnabledOf(String routineId) {
    final r = getById(routineId);
    // Routine 모델에 ttsEnabled 필드가 있다고 가정 (없으면 true 기본)
    return r?.ttsEnabled ?? true;
  }

  /// 루틴 TTS on/off 저장
  Future<void> setRoutineTts(String routineId, bool enabled) async {
    final r = getById(routineId);
    if (r == null) return;
    if (_isGuest) {
      await _updateFields(routineId, {'ttsEnabled': enabled});
      return;
    }

    // 1) 메모리 먼저 반영
    final updated = r.copyWith(ttsEnabled: enabled);
    _updateInMemoryRoutine(updated);
    notifyListeners();

    // 2) Firestore 저장
    await _updateFields(routineId, {
      'ttsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 메모리 캐시에 동일 ID의 루틴을 교체
  void _updateInMemoryRoutine(Routine updated) {
    final idx = allRoutines.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      allRoutines[idx] = updated;
    }
  }
}
