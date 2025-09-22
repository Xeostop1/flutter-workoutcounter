import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../models/exercise.dart';

/// Routine <-> Firestore 변환 전담
class RoutineFirestore {
  /// DocumentSnapshot -> Routine
  static Routine fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};

    // Timestamp -> DateTime 로 변환해서 모델에 넣음(모델은 cloud_firestore 모름)
    DateTime? _toDate(dynamic v) =>
        v is Timestamp ? v.toDate()
            : v is int      ? DateTime.fromMillisecondsSinceEpoch(v)
            : v is String   ? DateTime.tryParse(v)
            : v as DateTime?;

    final itemsRaw = (m['items'] as List?) ?? const [];
    final items = itemsRaw
        .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Routine(
      id: doc.id,
      title: (m['title'] ?? '') as String,
      categoryId: (m['categoryId'] ?? Routine.freeCategoryId) as String,
      items: items,
      ownerUid: m['ownerUid'] as String?,
      favorite: (m['favorite'] as bool?) ?? false,
      archived: (m['archived'] as bool?) ?? false,
      isDraft: (m['isDraft'] as bool?) ?? false,
      createdAt: _toDate(m['createdAt']),
      updatedAt: _toDate(m['updatedAt']),
    );
  }

  /// Routine -> Firestore 쓰기 맵 (신규 생성)
  static Map<String, dynamic> toCreateMap(Routine r, {required String ownerUid}) {
    return {
      'title'     : r.title,
      'categoryId': r.categoryId,
      'items'     : r.items.map((e) => e.toMap()).toList(),
      'ownerUid'  : ownerUid,
      'favorite'  : r.favorite,
      'archived'  : r.archived,
      'isDraft'   : r.isDraft,
      'createdAt' : FieldValue.serverTimestamp(),
      'updatedAt' : FieldValue.serverTimestamp(),
    };
  }

  /// Routine -> Firestore 업데이트 맵 (부분 업데이트 포함)
  static Map<String, dynamic> toUpdateMap(Routine r) {
    return {
      'title'     : r.title,
      'categoryId': r.categoryId,
      'items'     : r.items.map((e) => e.toMap()).toList(),
      'favorite'  : r.favorite,
      'archived'  : r.archived,
      'isDraft'   : r.isDraft,
      'updatedAt' : FieldValue.serverTimestamp(),
      // createdAt은 그대로 유지
    };
  }
}
