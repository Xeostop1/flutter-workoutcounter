import 'package:flutter/material.dart';

import 'routine_create_page.dart';

class RoutineEditPage extends StatelessWidget {
  const RoutineEditPage({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return RoutineCreatePage(routineId: routineId);
  }
}
