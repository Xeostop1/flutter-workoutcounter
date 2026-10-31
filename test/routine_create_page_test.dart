import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:counter_01/models/exercise.dart';
import 'package:counter_01/models/routine.dart';
import 'package:counter_01/pages/routines/routine_create_page.dart';
import 'package:counter_01/pages/routines/routine_edit_page.dart';
import 'package:counter_01/viewmodels/routines_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Finder _field(int index) => find.byType(TextField).at(index);
TextEditingController _controller(WidgetTester tester, int index) =>
    tester.widget<TextField>(_field(index)).controller!;

const _editRoutine = Routine(
  id: 'back',
  title: '등',
  categoryId: 'test',
  items: [
    Exercise(
      id: 'deadlift',
      name: '데드리프트',
      sets: 3,
      reps: 20,
      repSeconds: 4,
      isTransient: true,
    ),
    Exercise(id: 'pulldown', name: '암풀다운', sets: 4, reps: 20, repSeconds: 2),
    Exercise(id: 'row', name: '시티드로우', sets: 3, reps: 15, repSeconds: 3),
    Exercise(id: 'high', name: '하이로우', sets: 5, reps: 12, repSeconds: 3),
  ],
);
Finder _tile(String id) => find.byKey(ValueKey(id));
bool _saveEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Pretendard')..addFont(
          rootBundle.load('assets/fonts/Pretendard/Pretendard-Regular.ttf'),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('기본 등록 화면은 참고 이미지의 위치와 크기로 표시한다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _preview(tester, 'empty');
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('create-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      for (final point in [const Offset(188, 166), const Offset(188, 262)]) {
        final offset = (point.dy.toInt() * image.width + point.dx.toInt()) * 4;
        expect(
          [for (var i = 0; i < 3; i++) pixels!.getUint8(offset + i)],
          [39, 42, 48],
        );
      }
      final borderOffset = (325 * image.width + 300) * 4;
      expect(
        [for (var i = 0; i < 3; i++) pixels!.getUint8(borderOffset + i)],
        [102, 102, 102],
      );
      image.dispose();
    });
    expect(tester.getRect(_field(0)), const Rect.fromLTWH(28, 102, 320, 68));
    expect(tester.getRect(_field(1)), const Rect.fromLTWH(28, 210, 320, 54));
    expect(tester.getRect(_field(2)), const Rect.fromLTWH(269, 288, 79, 38));
    expect(
      tester.getRect(
        find.descendant(of: _field(0), matching: find.byType(InputDecorator)),
      ),
      const Rect.fromLTWH(28, 102, 320, 68),
    );
    expect(
      tester.getRect(
        find.descendant(of: _field(2), matching: find.byType(InputDecorator)),
      ),
      const Rect.fromLTWH(269, 288, 79, 38),
    );
    expect(
      tester.getRect(find.byType(FilledButton)),
      const Rect.fromLTWH(16, 720, 343, 61),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('개').hitTestable(), findsOneWidget);
    expect(find.text('회').hitTestable(), findsOneWidget);
    expect(find.text('초').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('입력 후 추가하면 목록에 운동을 표시하고 입력칸을 비운다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _type(tester, 0, '등');
    await _fillExercise(tester, '데드리프트');
    FocusScope.of(tester.element(_field(4))).unfocus();
    await tester.pumpAndSettle();
    await _preview(tester, 'filled');
    await _add(tester);
    expect(find.text('데드리프트'), findsOneWidget);
    expect(find.text('3/20'), findsOneWidget);
    expect(_controller(tester, 1).text, isEmpty);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await _preview(tester, 'one-exercise');
  });

  testWidgets('여러 운동은 가로로 넘기며 확인할 수 있다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _type(tester, 0, '등');
    for (final name in ['데드리프트', '암풀다운', '시티드로우', '하이로우']) {
      await _fillExercise(tester, name);
      await _add(tester);
    }
    await _preview(tester, 'multiple');
    await tester.drag(find.byType(ListView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('하이로우').hitTestable(), findsOneWidget);
  });

  testWidgets('운동 목록 편집을 누르면 등록 중인 운동도 삭제할 수 있다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _type(tester, 0, '등');
    await _fillExercise(tester, '데드리프트');
    await _add(tester);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tap(find.text('운동 목록'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);
    await _preview(tester, 'list-edit');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('데드리프트'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('타일을 눌러 운동을 수정해도 중복 항목이 생기지 않는다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _fillExercise(tester, '데드리프트');
    await _add(tester);
    await tester.tap(find.text('데드리프트'));
    await tester.pumpAndSettle();
    expect(_controller(tester, 1).text, '데드리프트');
    await _type(tester, 3, '15');
    await _add(tester);
    expect(find.text('3/15'), findsOneWidget);
    expect(find.text('3/20'), findsNothing);
  });

  testWidgets('0이나 빈 입력으로는 운동을 추가하지 않는다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _fillExercise(tester, '스쿼트');
    await _type(tester, 2, '0');
    await _add(tester);
    expect(find.text('운동명과 숫자를 모두 입력해주세요.'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('저장 실패 시 입력과 목록을 유지하고 같은 내용으로 재시도한다', (tester) async {
    final routines = _Routines()..error = StateError('오프라인');
    await _pumpPage(tester, routines);
    await _type(tester, 0, '등');
    await _fillExercise(tester, '데드리프트');
    await _add(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('루틴을 저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
    expect(_controller(tester, 0).text, '등');
    expect(find.text('3/20'), findsOneWidget);
    routines.error = null;
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(routines.savedTitle, '등');
    expect(routines.savedItems.single.name, '데드리프트');
    expect(routines.savedItems.single.repSeconds, 3);
    expect(find.text('루틴 목록 화면'), findsOneWidget);
  });

  testWidgets('저장 중에는 중복 저장과 입력 변경을 막는다', (tester) async {
    final routines = _Routines()..pending = Completer<void>();
    await _pumpPage(tester, routines);
    await _type(tester, 0, '등');
    await _fillExercise(tester, '데드리프트');
    await _add(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('저장 중...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<AbsorbPointer>(find.byType(AbsorbPointer).last).absorbing,
      isTrue,
    );
    expect(routines.attempts, 1);
    routines.pending!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('뒤로가기 취소 시 작성하던 내용을 유지한다', (tester) async {
    await _pumpPage(tester, _Routines());
    await _type(tester, 0, '작성중');
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('종료하시겠어요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(_controller(tester, 0).text, '작성중');
  });

  testWidgets('작은 화면과 큰 글씨에서도 저장 버튼까지 스크롤할 수 있다', (tester) async {
    await _pumpPage(
      tester,
      _Routines(),
      size: const Size(320, 568),
      textScale: 2,
    );
    await _type(tester, 0, '아주 긴 루틴 이름');
    await _fillExercise(tester, '시티드로우');
    await _add(tester);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'small');
  });

  testWidgets('키보드가 열려도 시간 입력칸과 추가 버튼에 접근할 수 있다', (tester) async {
    await _pumpPage(tester, _Routines(), keyboard: 300);
    await _type(tester, 0, '등');
    await _fillExercise(tester, '데드리프트');
    expect(_field(4).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _preview(tester, 'keyboard');
    await _add(tester);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('공유 수정 화면은 기존 운동과 제목을 유지한다', (tester) async {
    final routines = _Routines()
      ..existing = const Routine(
        id: 'saved',
        title: '등',
        categoryId: 'test',
        items: [
          Exercise(id: 'e', name: '데드리프트', sets: 3, reps: 20, repSeconds: 3),
        ],
      );
    await _pumpPage(tester, routines);
    expect(_controller(tester, 0).text, '등');
    expect(find.text('3/20'), findsOneWidget);
    expect(find.byTooltip('루틴 삭제'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
    await _type(tester, 0, '등 수정');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(routines.updatedId, 'saved');
    expect(routines.savedTitle, '등 수정');
  });

  group('루틴 수정', () {
    testWidgets('첫 운동 자동 선택과 변경 전 저장 비활성화', (tester) async {
      await _pumpPage(tester, _Routines()..existing = _editRoutine);
      expect(_controller(tester, 1).text, '데드리프트');
      expect(_controller(tester, 2).text, '3');
      expect(_controller(tester, 4).text, '4');
      expect(_saveEnabled(tester), isFalse);
      expect(tester.getRect(_field(0)), const Rect.fromLTWH(28, 102, 320, 68));
      expect(tester.getCenter(find.byTooltip('루틴 삭제')), const Offset(347, 74));
      final material = find
          .descendant(of: _tile('deadlift'), matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(material).color, Colors.white);
      await _preview(tester, 'edit-selected');
    });

    testWidgets('카드 선택만으로 데이터가 변경되지 않는다', (tester) async {
      await _pumpPage(tester, _Routines()..existing = _editRoutine);
      for (final id in ['pulldown', 'row', 'high']) {
        if (_tile(id).hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(_tile(id));
          await tester.pumpAndSettle();
        }
        await tester.tap(_tile(id));
        await tester.pumpAndSettle();
        final exercise = _editRoutine.items.firstWhere((e) => e.id == id);
        expect(_controller(tester, 1).text, exercise.name);
        expect(_controller(tester, 4).text, '${exercise.repSeconds}');
        expect(_saveEnabled(tester), isFalse);
        await _preview(tester, 'edit-$id');
      }
    });

    testWidgets('플러스 없이 저장해도 수정값과 식별자를 보존한다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 2, '5');
      await _type(tester, 3, '15');
      await _type(tester, 4, '3');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(_saveEnabled(tester), isTrue);
      await _preview(tester, 'edit-pending');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      final saved = routines.savedItems.first;
      expect(
        [saved.id, saved.sets, saved.reps, saved.repSeconds, saved.isTransient],
        ['deadlift', 5, 15, 3, true],
      );
      expect(routines.savedItems.length, 4);
      expect(_editRoutine.items.first.sets, 3);
      expect(find.text('루틴 목록 화면'), findsOneWidget);
    });

    testWidgets('카드 전환 시 앞 운동의 수정값을 잃지 않는다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 2, '5');
      await tester.tap(_tile('pulldown'));
      await tester.pumpAndSettle();
      expect(_controller(tester, 1).text, '암풀다운');
      expect(_saveEnabled(tester), isTrue);
      expect(routines.updates, 0);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.savedItems.first.sets, 5);
      expect(routines.savedItems[1].sets, 4);
    });

    testWidgets('잘못된 값이면 선택 이동과 서버 저장을 막는다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 2, '0');
      await tester.tap(_tile('pulldown'));
      await tester.pumpAndSettle();
      expect(_controller(tester, 1).text, '데드리프트');
      expect(_controller(tester, 2).text, '0');
      expect(find.text('운동명과 숫자를 모두 입력해주세요.'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.updates, 0);
      expect(_controller(tester, 2).text, '0');
    });

    testWidgets('플러스는 선택 운동에만 적용하고 선택을 유지한다', (tester) async {
      await _pumpPage(tester, _Routines()..existing = _editRoutine);
      await _type(tester, 2, '5');
      await _type(tester, 3, '15');
      await _add(tester);
      expect(_controller(tester, 1).text, '데드리프트');
      expect(
        find.descendant(of: _tile('deadlift'), matching: find.text('5/15')),
        findsOneWidget,
      );
      expect(_saveEnabled(tester), isTrue);
      await _preview(tester, 'edit-applied');
    });

    testWidgets('동일한 값 적용은 변경으로 취급하지 않는다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _add(tester);
      expect(_saveEnabled(tester), isFalse);
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      expect(find.text('종료하시겠어요?'), findsNothing);
      expect(find.text('루틴 목록 화면'), findsOneWidget);
      expect(routines.updates, 0);
    });

    testWidgets('새 운동 입력은 버리지 않고 플러스 추가를 안내한다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await tester.tap(_tile('deadlift'));
      await tester.pumpAndSettle();
      expect(_controller(tester, 1).text, isEmpty);
      await _fillExercise(tester, '새 운동');
      await tester.tap(_tile('pulldown'));
      await tester.pumpAndSettle();
      expect(_controller(tester, 1).text, '새 운동');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.updates, 0);
      expect(find.text('입력 중인 운동을 + 버튼으로 추가한 뒤 진행해주세요.'), findsWidgets);
      await _add(tester);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.savedItems.length, 5);
      expect(routines.savedItems.last.name, '새 운동');
      expect(routines.savedItems.map((e) => e.id).toSet().length, 5);
    });

    testWidgets('수정값을 원래대로 되돌리면 다시 저장하지 않아도 된다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 2, '5');
      await _add(tester);
      expect(_saveEnabled(tester), isTrue);
      await _type(tester, 2, '3');
      await _add(tester);
      expect(_saveEnabled(tester), isFalse);
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      expect(find.text('종료하시겠어요?'), findsNothing);
      expect(routines.updates, 0);
    });

    testWidgets('마지막 운동을 삭제하면 입력을 비우고 저장을 막는다', (tester) async {
      final routines = _Routines()
        ..existing = _editRoutine.copyWith(items: [_editRoutine.items.first]);
      await _pumpPage(tester, routines);
      await _preview(tester, 'edit-single');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(_controller(tester, 1).text, isEmpty);
      expect(_controller(tester, 2).text, isEmpty);
      expect(_saveEnabled(tester), isFalse);
      expect(routines.deletes, 0);
      await _preview(tester, 'edit-empty');
    });

    testWidgets('다른 운동을 삭제해도 현재 수정 중인 값은 보존한다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 2, '5');
      await tester.tap(
        find.descendant(
          of: _tile('pulldown'),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(_controller(tester, 2).text, '5');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.savedItems.map((e) => e.id), ['deadlift', 'row', 'high']);
      expect(routines.savedItems.first.sets, 5);
    });

    testWidgets('목록 편집 버튼은 삭제 표시만 전환한다', (tester) async {
      await _pumpPage(tester, _Routines()..existing = _editRoutine);
      expect(find.byIcon(Icons.close), findsNWidgets(4));
      await tester.tap(find.text('운동 목록'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing);
      expect(_saveEnabled(tester), isFalse);
    });

    testWidgets('저장 실패 후 같은 수정값으로 다시 저장할 수 있다', (tester) async {
      final routines = _Routines()
        ..existing = _editRoutine
        ..error = StateError('오프라인');
      await _pumpPage(tester, routines);
      await _type(tester, 2, '5');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('루틴을 저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
      expect(_controller(tester, 2).text, '5');
      expect(_saveEnabled(tester), isTrue);
      routines.error = null;
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.updates, 2);
      expect(routines.savedItems.first.sets, 5);
      expect(_editRoutine.items.first.sets, 3);
    });

    testWidgets('루틴 삭제 확인 취소와 실패 재시도를 처리한다', (tester) async {
      final routines = _Routines()
        ..existing = _editRoutine
        ..error = StateError('오프라인');
      await _pumpPage(tester, routines);
      await tester.tap(find.byTooltip('루틴 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('아니요'));
      await tester.pumpAndSettle();
      expect(routines.deletes, 0);
      await tester.tap(find.byTooltip('루틴 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('네'));
      await tester.pumpAndSettle();
      expect(find.text('루틴을 삭제하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
      expect(find.byType(RoutineEditPage), findsOneWidget);
      routines.error = null;
      await tester.tap(find.byTooltip('루틴 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('네'));
      await tester.pumpAndSettle();
      expect(routines.deletes, 2);
      expect(routines.deletedId, 'back');
      expect(find.text('루틴 목록 화면'), findsOneWidget);
    });

    testWidgets('나가기 취소는 수정값을 유지하고 종료 확인만 버린다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(tester, routines);
      await _type(tester, 4, '10');
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(_controller(tester, 4).text, '10');
      await tester.tap(find.byTooltip('뒤로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('종료'));
      await tester.pumpAndSettle();
      expect(routines.updates, 0);
      expect(_editRoutine.items.first.repSeconds, 4);
    });

    testWidgets('큰 글씨와 키보드에서도 수정 후 저장할 수 있다', (tester) async {
      final routines = _Routines()..existing = _editRoutine;
      await _pumpPage(
        tester,
        routines,
        size: const Size(320, 568),
        textScale: 2,
        keyboard: 200,
      );
      await _type(tester, 2, '5');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'edit-small');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(routines.savedItems.first.sets, 5);
    });
  });
}

Future<void> _type(WidgetTester tester, int index, String value) async {
  await tester.ensureVisible(_field(index));
  await tester.pumpAndSettle();
  await tester.enterText(_field(index), value);
  await tester.pump();
}

Future<void> _fillExercise(WidgetTester tester, String name) async {
  for (final entry in {1: name, 2: '3', 3: '20', 4: '3'}.entries) {
    await _type(tester, entry.key, entry.value);
  }
}

Future<void> _add(WidgetTester tester) async {
  await tester.ensureVisible(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(
  WidgetTester tester,
  _Routines routines, {
  Size size = const Size(375, 812),
  double textScale = 1,
  double keyboard = 0,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(routines.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<RoutinesViewModel>.value(
      value: routines,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Pretendard'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 44),
            textScaler: TextScaler.linear(textScale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('create-preview'),
            child: child,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => routines.existing == null
                      ? const RoutineCreatePage()
                      : RoutineEditPage(routineId: routines.existing!.id),
                ),
              ),
              child: const Text('루틴 목록 화면'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('루틴 목록 화면'));
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/icons/icon-edit.png'),
      tester.element(find.byType(RoutineCreatePage)),
    ),
  );
  await tester.pump();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CREATE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('create-preview')),
  );
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  final shadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = name.startsWith('edit-')
          ? 'build/routine-edit-previews'
          : 'build/routine-create-previews';
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = shadows;
    repaint(boundary);
    await tester.pump();
  }
}

class _Routines extends ChangeNotifier implements RoutinesViewModel {
  Object? error;
  Completer<void>? pending;
  Routine? existing;
  String? savedTitle;
  String? updatedId;
  List<Exercise> savedItems = [];
  int attempts = 0;
  int updates = 0;
  int deletes = 0;
  String? deletedId;
  @override
  Routine? getById(String id) => existing;
  @override
  Future<String> createRoutine({
    required String title,
    String? categoryId,
    List<Exercise> items = const [],
    bool favorite = false,
    bool archived = false,
    bool isDraft = false,
  }) async {
    attempts++;
    savedTitle = title;
    savedItems = List.of(items);
    if (error != null) {
      throw error!;
    }
    if (pending != null) {
      await pending!.future;
    }
    return 'saved';
  }

  @override
  Future<void> updateRoutine(
    String id, {
    required String title,
    required List<Exercise> items,
  }) async {
    updates++;
    updatedId = id;
    savedTitle = title;
    savedItems = List.of(items);
    if (error != null) throw error!;
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    deletes++;
    deletedId = id;
    if (error != null) throw error!;
    if (pending != null) await pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
