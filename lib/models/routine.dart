class Routine {
  final String id;
  String name;
  int sets;
  int reps;
  double secPerRep; // 1회당 걸리는 시간(초)

  bool favorite;
  DateTime updatedAt;
  int restSec;

  Routine({
    required this.id,
    required this.name,

    this.sets = 3,
    this.reps = 15,
    this.restSec = 10,
    this.secPerRep = 2.0,
    this.favorite = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Routine copyWith({
    String? name,
    int? sets,
    int? reps,
    double? secPerRep,
    bool? favorite,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      secPerRep: secPerRep ?? this.secPerRep,
      favorite: favorite ?? this.favorite,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sets': sets,
    'reps': reps,
    'secPerRep': secPerRep,
    'favorite': favorite,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'],
    name: j['name'],
    sets: j['sets'],
    reps: j['reps'],
    secPerRep: (j['secPerRep'] as num).toDouble(),
    favorite: j['favorite'] ?? false,
    updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
  );
}
