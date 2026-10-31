import 'package:counter_01/pages/onboarding/onboarding_page.dart';
import 'package:counter_01/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Auth extends ChangeNotifier implements AuthViewModel {
  final List<int> saved = [];
  @override
  Future<void> completeOnboarding({required int weeklyTarget}) async {
    saved.add(weeklyTarget);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('입력과 대기만으로 이동하거나 저장하지 않고 이전에서 수정할 수 있다', (tester) async {
    final auth = _Auth();
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('홈 도착')),
        ),
      ],
    );
    addTearDown(auth.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('이전'), findsNothing);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(TextField), findsOneWidget);
    expect(auth.saved, isEmpty);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('시작하기'), findsOneWidget);
    expect(auth.saved, isEmpty);
    await tester.tap(find.text('이전'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '3',
    );
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(auth.saved, [5]);
    expect(find.text('홈 도착'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
