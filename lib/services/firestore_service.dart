//
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';
//
// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> saveUser(UserModel user) async{
//     try {
//       await _firestore.collection('users').doc(user.uuid).set(user.toMap());
//     } catch(e) {
//       print('error $e');
//       rethrow;
//     }
//     }
//
//     Future<UserModel?> getUser(String uuid) async{
//       try{
//         final doc = await _firestore.collection('users').doc(uuid).get();
//         if (doc.exists){
//           return UserModel.fromMap(doc.data()!);
//         }else{
//           return null;
//         }
//       }catch(e){
//         print('error $e');
//         rethrow;
//       }
//
//     }
//
//
// }
//
