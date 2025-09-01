import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/tts_repository.dart';
import 'repositories/record_repository.dart';
import 'repositories/routine_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthRepository _auth = FakeAuthRepository(); // 나중에 Firebase로 교체
  late final TtsRepository _tts = TtsRepository();
  late final RecordRepository _records = MemoryRecordRepository();
  late final RoutineRepository _routines = SeedRoutineRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(_auth)),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(_tts)),
        ChangeNotifierProvider(create: (_) => RecordsViewModel(_records)),
        ChangeNotifierProvider(create: (_) => RoutinesViewModel(_routines)),
        ChangeNotifierProvider(create: (c) =>
            CounterViewModel(_tts, c.read<RecordsViewModel>())),
      ],
      child: Builder(
        builder: (context) {
          final router = createRouter(context);
          return MaterialApp.router(
            title: 'SPORKLE',
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFFFF4A3A),
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
