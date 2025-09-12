import 'package:flutter/material.dart';
import '../../models/routine.dart';

class RoutineList extends StatelessWidget {
  final List<Routine> routines;
  final void Function(Routine) onPlay;

  const RoutineList({super.key, required this.routines, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in routines) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            dense: true,
            title: Text(
              r.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              _subtitle(r),
              style: const TextStyle(color: Color(0xFFBEBEBE)),
            ),
            trailing: _PlayPill(onTap: () => onPlay(r)),
            onTap: () => onPlay(r),
          ),
          Divider(color: Colors.white.withOpacity(0.12), height: 12),
        ],
      ],
    );
  }

  String _subtitle(Routine r) {
    final items = r.items;
    if (items.isEmpty) return '운동 없음';
    final first = items.first.name;
    if (items.length == 1) return first;
    return '$first 외 ${items.length - 1}개의 운동';
  }
}

class _PlayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.asset(
          'assets/images/icon-play_L.png',
          width: 38,
          height: 37,
        ),
      ),
    );
  }
}
