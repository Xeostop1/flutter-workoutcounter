import 'package:counter_01/repositories/record_repository.dart';
import 'package:counter_01/viewmodels/records_viewmodel.dart';
import 'package:counter_01/widgets/bottom_nav_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('복구 실패 안내에서 저장을 다시 시도할 수 있다', (tester) async {
    final records = _PendingRecords();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (_, __, child) => BottomNavShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const Center(child: Text('홈 화면')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(records.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<RecordsViewModel>.value(
        value: records,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('저장하지 못한 운동 기록 1개가 기기에 보관되어 있어요.'), findsOneWidget);
    await tester.tap(find.text('다시 저장하기'));
    await tester.pumpAndSettle();
    expect(records.retried, isTrue);
  });
}

class _PendingRecords extends RecordsViewModel {
  _PendingRecords() : super(InMemoryRecordRepository());
  bool retried = false;

  @override
  int get pendingCount => 1;

  @override
  Future<void> retryPendingRecords() async {
    retried = true;
  }
}
