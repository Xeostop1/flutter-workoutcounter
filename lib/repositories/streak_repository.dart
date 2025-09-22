import 'package:shared_preferences/shared_preferences.dart';

abstract class StreakRepository {
  Future<DateTime?> getLastOpen();
  Future<int?> getDay();
  Future<void> save(DateTime lastOpen, int day);
}

class PrefsStreakRepository implements StreakRepository {
  static const _kLastOpen = 'streak_last_open'; // yyyy-MM-dd
  static const _kDay = 'streak_day'; // int

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseDate(String? v) {
    if (v == null || v.isEmpty) return null;
    final parts = v.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<DateTime?> getLastOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseDate(prefs.getString(_kLastOpen));
  }

  @override
  Future<int?> getDay() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kDay);
    return v;
  }

  @override
  Future<void> save(DateTime lastOpen, int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastOpen, _fmt(_dateOnly(lastOpen)));
    await prefs.setInt(_kDay, day);
  }
}
