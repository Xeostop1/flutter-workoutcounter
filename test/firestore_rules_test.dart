import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore는 로그인한 사용자의 문서만 허용한다', () {
    final rules = File('firestore.rules').readAsStringSync();
    final config =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(config['firestore'], {'rules': 'firestore.rules'});
    expect(rules, contains('request.auth != null'));
    expect(rules, contains('request.auth.uid == uid'));
    expect(rules, contains('match /users/{uid}'));
    expect(rules, contains('match /{document=**}'));
    expect(rules, isNot(contains('allow read, write: if true')));
  });

  test('회원탈퇴는 사용자 데이터를 지운 뒤 Auth 계정을 삭제한다', () {
    final source = File(
      'lib/repositories/auth_repository.dart',
    ).readAsStringSync();
    final dataDeletion = source.indexOf('await _deleteUserData(user.uid)');
    final accountDeletion = source.indexOf('await user.delete()');

    expect(source, contains("const ['routines', 'workoutRecords']"));
    expect(source, contains('collection.limit(450).get()'));
    expect(dataDeletion, greaterThan(-1));
    expect(accountDeletion, greaterThan(dataDeletion));
  });

  test('Android Apple 로그인과 재인증은 Firebase 제공자 흐름을 사용한다', () {
    final source = File(
      'lib/repositories/auth_repository.dart',
    ).readAsStringSync();

    expect(source, contains('platform == TargetPlatform.android'));
    expect(source, contains('await _auth.signInWithProvider(provider)'));
    expect(source, contains('await user.reauthenticateWithProvider(provider)'));
  });

  test('루틴 삭제 실패 시 편집 화면을 유지하고 재시도를 안내한다', () {
    final source = File(
      'lib/pages/routines/routine_create_page.dart',
    ).readAsStringSync();

    expect(source, contains('if (!_isEditing || _saving) return'));
    expect(source, contains('setState(() => _saving = true)'));
    expect(source, contains("_showMessage('루틴을 삭제하지 못했어요. 다시 시도해주세요.')"));
  });

  test('계정 전환 후 이전 루틴 스트림 응답을 무시한다', () {
    final source = File(
      'lib/viewmodels/routines_viewmodel.dart',
    ).readAsStringSync();

    expect(source, contains('final generation = ++_bindGeneration'));
    expect(source, contains('if (generation != _bindGeneration) return;'));
    expect(source, contains('_selectedRoutineId = null'));
  });

  test('루틴 로딩 실패를 표시하고 재시도할 수 있다', () {
    final viewModel = File(
      'lib/viewmodels/routines_viewmodel.dart',
    ).readAsStringSync();
    final page = File(
      'lib/pages/routines/routine_page.dart',
    ).readAsStringSync();

    expect(viewModel, contains('Object? get loadError => _loadError'));
    expect(viewModel, contains('_loadError = e'));
    expect(viewModel, contains('void retryLoad() => bind()'));
    expect(page, contains("const Text('루틴을 불러오지 못했어요.')"));
    expect(page, contains('onRetry: vm.retryLoad'));
  });

  test('기존 사용자 튜토리얼 자동 완료 실패를 안내하고 재시도한다', () {
    final source = File('lib/pages/home/home_page.dart').readAsStringSync();

    expect(source, contains('unawaited(_completeTutorial())'));
    expect(source, isNot(contains('markHomeTutorialDone().catchError')));
    expect(source, contains("label: '다시 시도'"));
    expect(source, contains('_completeTutorial(openRoutines: openRoutines)'));
  });
}
