import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserToFirestore(User user) async {
    print('[FirestoreService] 사용자 정보 저장 함수 실행됨');

    final userRef = _firestore.collection('users').doc(user.uid);

    if (user.email == null) {
      print('[FirestoreService] 오류: 사용자 이메일이 null입니다');
      throw Exception('User email is null. Cannot save user data.');
    }

    final doc = await userRef.get();
    print('[FirestoreService] 해당 사용자 문서 존재 여부: ${doc.exists}');

    if (!doc.exists) {
      print('[FirestoreService] 새 사용자 문서를 생성합니다...');
      await userRef.set({
        'displayName': user.displayName ?? '',
        'email': user.email,
        'photoURL': user.photoURL ?? '',
        'provider': user.providerData.isNotEmpty ? user.providerData[0].providerId : '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'settings': {
          'ttsEnabled': false,
          'locale': 'ko',
          'timeZone': '',
          'notificationTokens': [],
          'theme': 'light',
          'appVersion': '1.0.0',
        }
      });
      print('[FirestoreService] 사용자 문서가 성공적으로 생성되었습니다!');
    } else {
      print('[FirestoreService] 기존 사용자입니다. 마지막 로그인 시간만 업데이트합니다...');
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      print('[FirestoreService] 마지막 로그인 시간이 업데이트되었습니다!');
    }
  }



}
