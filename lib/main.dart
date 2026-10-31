import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';

import 'app_router.dart' as app_router;
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/record_repository.dart';
import 'repositories/pending_workout_store.dart';
import 'repositories/guest_store.dart';
import 'repositories/guest_record_repository.dart';
import 'repositories/guest_migration.dart';
import 'repositories/user_settings_repository.dart';
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
        Provider<GuestStore>(create: (_) => GuestStore()),
        // 로그인 상태
        Provider<PendingWorkoutStore>(create: (_) => PendingWorkoutStore()),
        Provider<AuthRepository>(
          create: (ctx) => FirebaseAuthRepository(
            pendingWorkouts: ctx.read<PendingWorkoutStore>(),
          ),
        ),
        Provider<GuestMigration>(
          create: (ctx) {
            late final GuestMigration migration;
            final importer = FirestoreGuestImporter(
              isCurrent: (uid) => migration.isAllowed(uid),
            );
            migration = GuestMigration(
              ctx.read<GuestStore>(),
              writeRecord: importer.record,
              writeRoutine: importer.routine,
            );
            return migration;
          },
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            ctx.read<AuthRepository>(),
            guestStore: ctx.read<GuestStore>(),
            guestMigration: ctx.read<GuestMigration>(),
            settingsRepo: UserSettingsRepository(
              guestStore: ctx.read<GuestStore>(),
            ),
          ),
        ),
        // 운동 기록
        Provider<RecordRepository>(
          create: (ctx) => GuestRecordRepository(
            FirestoreRecordRepository(),
            ctx.read<GuestStore>(),
            currentUid: () => ctx.read<AuthViewModel>().dataUid,
            currentScope: () => ctx.read<AuthViewModel>().sessionGeneration,
          ),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, RecordsViewModel>(
          create: (ctx) => RecordsViewModel(
            ctx.read<RecordRepository>(),
            pendingWorkouts: ctx.read<PendingWorkoutStore>(),
            guestMigration: ctx.read<GuestMigration>(),
          ),
          update: (_, auth, records) {
            records!.bindAccount(auth.dataUid);
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
          create: (ctx) => RoutinesViewModel(
            guestStore: ctx.read<GuestStore>(),
            session: ctx.read<AuthViewModel>(),
          )..bind(),
        ),

        ChangeNotifierProxyProvider<AuthViewModel, CounterViewModel>(
          create: (ctx) => CounterViewModel(ctx.read<RecordsViewModel>()),
          update: (_, auth, counter) {
            counter!.bindAccount(auth.dataUid);
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
            theme: AppTheme.dark,
          );
        },
      ),
    );
  }
}
