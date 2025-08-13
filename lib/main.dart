import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'repositories/routine_repository.dart';
import 'repositories/record_repository.dart';
import 'services/storage_service.dart';
import 'viewmodels/routine_viewmodel.dart';
import 'viewmodels/record_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart'; // **** 온보딩/스킵/로그인 분기용

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  final routineVm = RoutineViewModel(RoutineRepository(storage));
  final recordVm = RecordViewModel(RecordRepository(storage));
  final settingsVm = SettingsViewModel(storage);
  final authVm = AuthViewModel(storage: storage); // **** 추가

  await Future.wait([routineVm.load(), recordVm.load(), settingsVm.load()]);
  // 스플래시에서 bootstrap()을 호출하므로 여기서는 호출하지 않아도 됨
  // (authVm.bootstrap()을 여기서 해도 되지만, 스플래시에서 하는 흐름을 유지)

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
  final RoutineViewModel routineVm;
  final RecordViewModel recordVm;
  final SettingsViewModel settingsVm;
  final AuthViewModel authVm;

  const MyApp({
    super.key,
    required this.routineVm,
    required this.recordVm,
    required this.settingsVm,
    required this.authVm,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => routineVm),
        ChangeNotifierProvider(create: (_) => recordVm),
        ChangeNotifierProvider(create: (_) => settingsVm),
        ChangeNotifierProvider(
          create: (_) => authVm,
        ), // **** 추가 (router redirect에서 구독)
      ],
      child: Builder(
        // **** buildRouter(context)를 쓰기 위해 Builder로 감쌈
        builder: (context) {
          final router = buildRouter(
            context,
          ); // **** 기존: buildRouter() → 수정: buildRouter(context)
          return MaterialApp.router(
            title: 'Workout Counter',
            theme: appTheme(),
            routerConfig: router, // **** 수정된 router 사용
          );
        },
      ),
    );
  }
}
