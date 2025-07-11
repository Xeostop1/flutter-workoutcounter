//
// class UserModel {
//   final String uuid;
//   final List<String> routines;
//   final List<String> stamps;
//
//   UserModel({
//     required this.uuid,
//     required this.routines,
//     required this.stamps,
//   });
//
//   //팩토리 파일 생서자 사용, json 형태를 리스트로 바로 변경
//   factory UserModel.fromMap(Map<String, dynamic> map){
//     return UserModel(
//       uuid: map['uuid'] ?? '',
//       routines:List<String>.from(map['routines']?? []),
//       stamps:List<String>.from(map['stamps']?? []),
//
//     );
//   }
//
//   //파이어베이스 저장
//   Map<String, dynamic> toMap(){
//     return {
//       'uuid':uuid,
//       'routines':routines,
//       'stamps':stamps,
//     };
//   }
//
// }