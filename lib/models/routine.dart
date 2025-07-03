class Routine {
  final String name;
  final int sets;
  final int reps;

  Routine({
    required this.name,
    required this.sets,
    required this.reps,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets,
    'reps': reps,
  };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    name: json['name'],
    sets: json['sets'],
    reps: json['reps'],
  );
}
