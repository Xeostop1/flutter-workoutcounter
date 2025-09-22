import 'exercise.dart';

class Routine {
  /// “루틴 없이 운동하기” 등에 쓰는 가상의 카테고리
  static const String freeCategoryId = 'FREE';

  final String id;              // UUID (doc id)
  final String title;
  final String categoryId;      // 카테고리 UUID (FK) — 자유운동은 FREE 사용
  final List<Exercise> items;

  // --- 확장 메타 ---
  final String? ownerUid;       // 로그인 사용자 uid
  final bool favorite;          // 즐겨찾기
  final bool archived;          // 숨김/보관
  final bool isDraft;           // 편집 중 임시 루틴 여부
  final DateTime? createdAt;    // 생성 시각
  final DateTime? updatedAt;    // 수정 시각

  const Routine({
    required this.id,
    required this.title,
    required this.categoryId,
    this.items = const [],
    this.ownerUid,
    this.favorite = false,
    this.archived = false,
    this.isDraft = false,
    this.createdAt,
    this.updatedAt,
  });

  /// 대표 운동(없으면 기본값)
  Exercise get primary => items.isNotEmpty
      ? items.first
      : const Exercise(
    id: 'EMPTY',
    name: '운동',
    sets: 2,
    reps: 10,
    repSeconds: 2,
  );

  Routine copyWith({
    String? id,
    String? title,
    String? categoryId,
    List<Exercise>? items,
    String? ownerUid,
    bool? favorite,
    bool? archived,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
      ownerUid: ownerUid ?? this.ownerUid,
      favorite: favorite ?? this.favorite,
      archived: archived ?? this.archived,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore/Local 공용 직렬화
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'categoryId': categoryId,
    'items': items.map((e) => e.toMap()).toList(),
    'ownerUid': ownerUid,
    'favorite': favorite,
    'archived': archived,
    'isDraft': isDraft,
    // 날짜는 ISO로 저장(서버/클라 모두 안전), epoch를 쓰고 싶으면 msSinceEpoch로 바꿔도 OK
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Routine.fromMap(Map<String, dynamic> m) => Routine(
    id: m['id'] as String,
    title: (m['title'] ?? '') as String,
    categoryId: (m['categoryId'] ?? freeCategoryId) as String,
    items: (m['items'] as List<dynamic>? ?? const [])
        .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
        .toList(),
    ownerUid: m['ownerUid'] as String?,
    favorite: (m['favorite'] as bool?) ?? false,
    archived: (m['archived'] as bool?) ?? false,
    isDraft: (m['isDraft'] as bool?) ?? false,
    createdAt: _parseDate(m['createdAt']),
    updatedAt: _parseDate(m['updatedAt']),
  );

  // ===== 편의 생성자: 자유 운동 임시 루틴 =====
  factory Routine.free({
    required String id,
    required String title,
    String? ownerUid,
    List<Exercise> items = const [],
  }) {
    final now = DateTime.now();
    return Routine(
      id: id,
      title: title,
      categoryId: freeCategoryId,
      items: items,
      ownerUid: ownerUid,
      isDraft: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===== 내부 유틸 =====
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  String toString() =>
      'Routine($id, $title, items:${items.length}, fav:$favorite, draft:$isDraft)';
}
