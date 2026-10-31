import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_router.dart' as app_router;
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/record_repository.dart';
import 'repositories/pending_workout_store.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/counter_viewmodel.dart';
import 'viewmodels/records_viewmodel.dart';
import 'viewmodels/routines_viewmodel.dart';
import 'viewmodels/streak_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    final isApplePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isApplePlatform) {
      await Firebase.initializeApp();
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 로그인 상태
        Provider<PendingWorkoutStore>(create: (_) => PendingWorkoutStore()),
        Provider<AuthRepository>(
          create: (ctx) => FirebaseAuthRepository(
            pendingWorkouts: ctx.read<PendingWorkoutStore>(),
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        // 운동 기록
        Provider<RecordRepository>(create: (_) => FirestoreRecordRepository()),
        ChangeNotifierProxyProvider<AuthViewModel, RecordsViewModel>(
          create: (ctx) => RecordsViewModel(
            ctx.read<RecordRepository>(),
            pendingWorkouts: ctx.read<PendingWorkoutStore>(),
          ),
          update: (_, auth, records) {
            records!.bindAccount(auth.user?.uid);
            return records;
          },
        ),
        ChangeNotifierProxyProvider<RecordsViewModel, StreakViewModel>(
          create: (_) => StreakViewModel(),
          update: (_, records, streak) {
            streak!.syncWorkoutRecords(records.records);
            return streak;
          },
        ),

        // 루틴 목록
        ChangeNotifierProvider<RoutinesViewModel>(
          create: (_) => RoutinesViewModel()..bind(),
        ),

        ChangeNotifierProxyProvider<AuthViewModel, CounterViewModel>(
          create: (ctx) => CounterViewModel(ctx.read<RecordsViewModel>()),
          update: (_, auth, counter) {
            counter!.bindAccount(auth.user?.uid);
            return counter;
          },
        ),
      ],
      child: Builder(
        builder: (ctx) {
          final router = app_router.createRouter(ctx);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: ThemeData(
              fontFamily: 'Pretendard',
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFF6B35),
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
