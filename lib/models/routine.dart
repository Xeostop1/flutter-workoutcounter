import 'exercise.dart';

class Routine {
  final String id;   // **** String으로 변경
  final String title;
  final List<Exercise> items;
  bool favorite;

  Routine({
    required this.id,
    required this.title,
    required this.items,
    this.favorite = false,
  });

  Exercise get primary => items.first;
}
