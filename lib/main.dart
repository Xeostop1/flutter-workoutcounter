import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'repositories/routine_repository.dart';
import 'repositories/record_repository.dart';
import 'services/storage_service.dart';

// VMs
import 'viewmodels/routine_viewmodel.dart';
import 'viewmodels/record_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';

// ★ 라우터는 alias 로 임포트
import 'app_router.dart' as app_router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();

  final routineVm = RoutineViewModel(RoutineRepository(storage));
  final recordVm = RecordViewModel(RecordRepository(storage));
  final settingsVm = SettingsViewModel(storage);
  final authVm = AuthViewModel(storage: storage); // ★ named parameter

  // ★ 순차 로드(어떤 load()가 Future가 아닐 수 있어서)
  await routineVm.load();
  await recordVm.load();
  await settingsVm.load();
  await authVm.load();

  runApp(
    MyApp(
      routineVm: routineVm,
      recordVm: recordVm,
      settingsVm: settingsVm,
      authVm: authVm,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.routineVm,
    required this.recordVm,
    required this.settingsVm,
    required this.authVm,
  });

  final RoutineViewModel routineVm;
  final RecordViewModel recordVm;
  final SettingsViewModel settingsVm;
  final AuthViewModel authVm;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => routineVm),
        ChangeNotifierProvider(create: (_) => recordVm),
        ChangeNotifierProvider(create: (_) => settingsVm),
        ChangeNotifierProvider(create: (_) => authVm),
      ],
      // ★ buildRouter(context)를 위해 한 번 감쌈
      child: Builder(
        builder: (context) {
          final router = app_router.buildRouter(context); // ★ alias 사용
          return MaterialApp.router(
            title: 'Workout Counter',
            theme: appTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
