// lib/viewmodels/routines_viewmodel.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/routine.dart';
import '../models/routine_category.dart';
import '../models/exercise.dart';
import '../data/routine_firestore.dart';

/// 루틴 정렬 옵션
enum RoutineOrder {
  recent,       // 최근 수정순(기본)
  titleAsc,     // 제목 오름차순
  titleDesc,    // 제목 내림차순
  favoriteFirst // 즐겨찾기 먼저
}

/// 루틴/카테고리 상태 (Firestore 연동)
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
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────────────────────
  // Firestore & Auth
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('로그인 필요: FirebaseAuth.currentUser가 null 입니다.');
    }
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _colOf(String uid) =>
      _db.collection('users').doc(uid).collection('routines');

  CollectionReference<Map<String, dynamic>> get _col => _colOf(_uid);

  // ─────────────────────────────────────────────────────────────────────────────
  // 메모리 캐시 (UI 호환)
  List<RoutineCategory> categories = [];
  List<Routine> allRoutines = [];

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

  /// ✅ 선택 해제(루틴 없이 운동하기용)
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

  /// ✅ 읽기용 전체 목록(다른 화면에서 hasAny 체크 용이)
  List<Routine> get items => List.unmodifiable(allRoutines);

  // 선택된 카테고리(UUID)
  String? selectedCategoryId;

  // ✅ 정렬 상태(기본: recent)
  RoutineOrder _order = RoutineOrder.recent;
  RoutineOrder get order => _order;

  void setOrder(RoutineOrder newOrder) {
    if (_order == newOrder) return;
    _order = newOrder;
    // 정렬만 바꿔도 UI가 다시 정렬되어야 하므로 알림
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 초기 로드 / 실시간 바인딩
  StreamSubscription? _sub;                 // routines 컬렉션 구독
  StreamSubscription<User?>? _authSub;      // auth 변화 구독

  /// Firestore와 실시간 동기화 시작
  /// - 로그인 전: 캐시 비움
  /// - 로그인 후: 해당 uid 경로로 재구독
  void bind() {
    // 이미 켜져 있으면 재설치
    _authSub?.cancel();
    _authSub = _auth.userChanges().listen((u) {
      // 기존 컬렉션 구독 해제
      _sub?.cancel();
      _sub = null;

      // 캐시 초기화 후 알림
      allRoutines = [];
      notifyListeners();

      if (u == null) {
        if (kDebugMode) print('[RoutinesVM] bind: user=null (로그인 전)');
        return; // 로그인 되면 자동으로 재호출됨
      }

      if (kDebugMode) print('[RoutinesVM] bind: user=${u.uid} → 컬렉션 구독 시작');
      _sub = _colOf(u.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .listen((qs) {
        allRoutines = qs.docs.map(RoutineFirestore.fromDoc).toList();

        // 선택 카테고리 기본값(최초 1회)
        selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;

        notifyListeners();
      }, onError: (e, st) {
        if (kDebugMode) {
          print('RoutinesViewModel.bind stream error: $e');
        }
      });
    });
  }

  /// Firestore/Auth 구독 해제
  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  /// (선택) 카테고리 시드 로드
  void loadSeed({
    required List<RoutineCategory> cats,
  }) {
    categories = cats;
    selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 표시용 유틸

  String categoryNameById(String id) {
    final found = categories.where((c) => c.id == id);
    return found.isEmpty ? '기타' : found.first.name;
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
        return List<Routine>.from(list)
          ..sort((a, b) {
            // 문서의 favorite 필드 사용 (true 우선)
            final af = a.favorite ? 1 : 0;
            final bf = b.favorite ? 1 : 0;
            final favCmp = bf.compareTo(af);
            return favCmp != 0 ? favCmp : a.title.compareTo(b.title);
          });
    }
  }

  // (옵션) 화면에서 StreamBuilder를 쓰고 싶을 때 제공
  Stream<List<Routine>> routinesStream() {
    final u = _auth.currentUser;
    if (u == null) return const Stream.empty();
    return _colOf(u.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(RoutineFirestore.fromDoc).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 쓰기 API

  // 간단한 ID 생성기(패키지 없이) — 클라이언트 임시 id가 필요할 때만 사용
  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// 새 루틴 “초안”을 만들고 ID 반환 → 화면에서 이 ID로 편집 페이지 푸시
  Future<String> createDraft({String? title, String? categoryId}) async {
    final doc = _col.doc(); // Firestore auto id
    final cid = categoryId ??
        selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : Routine.freeCategoryId);
    final t = (title == null || title.trim().isEmpty) ? '새 루틴' : title.trim();

    final draft = Routine(
      id: doc.id,
      title: t,
      categoryId: cid,
      items: const [],
      ownerUid: _uid,
      isDraft: true,
      favorite: false,
      archived: false,
    );

    await doc.set(RoutineFirestore.toCreateMap(draft, ownerUid: _uid));
    // bind()가 켜져 있으면 실시간으로 allRoutines가 갱신됨
    return doc.id;
  }

  /// 제목 변경
  Future<void> setTitle(String routineId, String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    await _col.doc(routineId).update({
      'title': t,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(String routineId) async {
    final r = getById(routineId);
    if (r == null) return;
    await _col.doc(routineId).update({
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
    await _col.doc(routineId).update(
      RoutineFirestore.toUpdateMap(updated),
    );
  }

  /// 운동 삭제
  Future<void> removeExercise(String routineId, String exerciseId) async {
    final r = getById(routineId);
    if (r == null) return;
    final updated =
    r.copyWith(items: r.items.where((e) => e.id != exerciseId).toList());
    await _col.doc(routineId).update(
      RoutineFirestore.toUpdateMap(updated),
    );
  }

  /// 루틴 삭제
  Future<void> deleteRoutine(String routineId) async {
    await _col.doc(routineId).delete();
    if (_selectedRoutineId == routineId) {
      _selectedRoutineId = null;
      notifyListeners();
    }
  }

  /// ===== 새 루틴 생성 (편집 아님) =====
  Future<String> createRoutine({
    required String title,
    String? categoryId,
    List<Exercise> items = const [],
    bool favorite = false,
    bool archived = false,
    bool isDraft = false, // 생성 즉시 사용이니 기본 false
  }) async {
    final doc = _col.doc(); // auto id
    final cid = categoryId ??
        selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : Routine.freeCategoryId);

    final r = Routine(
      id: doc.id,
      title: title.trim().isEmpty ? '제목 없는 루틴' : title.trim(),
      categoryId: cid,
      items: items,
      ownerUid: _uid,
      favorite: favorite,
      archived: archived,
      isDraft: isDraft,
    );

    await doc.set(RoutineFirestore.toCreateMap(r, ownerUid: _uid));
    return doc.id;
  }
}
