import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_exe/main.dart';
import 'package:todo_exe/pro/pro_controller.dart';
import 'package:todo_exe/state/todo_store.dart';

void main() {
  testWidgets('부팅 → 메인 → 입력창으로 할 일 추가', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final store = TodoStore(clock: () => DateTime(2026, 9, 29, 13));
    await store.load();

    await tester.pumpWidget(TodoExeApp(store: store));
    expect(find.text('todo.exe'), findsOneWidget);

    // 부팅 애니메이션이 끝나고 시작 버튼이 나타난다.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // 처음 실행: 사용법 안내는 건너뛴다.
    await tester.tap(find.text('[ ESC ] 건너뛰기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('이 줄을 탭하면 완료돼요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '테스트 할 일 #qa !!');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.text('테스트 할 일'), findsOneWidget);
    expect(find.text('#qa'), findsOneWidget);
    expect(find.text('+ #05 추가됨'), findsOneWidget);

    // 줄을 탭하면 완료 처리된다.
    await tester.tap(find.text('이 줄을 탭하면 완료돼요'));
    await tester.pump();
    expect(store.data.tasks.first.done, isTrue);

    // 칩을 누르면 키보드가 유지되고, 입력 영역 밖을 탭하면 내려간다.
    await tester.tap(find.text('done'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('TODO [Version 1.0.0]'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('무료: 테마 잠김 → upgrade 화면 → (dev) PRO 켜면 테마 변경', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final pro = ProController(); // init() 을 부르지 않으면 스토어에 연결하지 않는다.
    final store = TodoStore(clock: () => DateTime(2026, 9, 29, 13), pro: pro);
    await store.load();

    await tester.pumpWidget(TodoExeApp(store: store));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // 처음 실행: 사용법 안내는 건너뛴다.
    await tester.tap(find.text('[ ESC ] 건너뛰기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> type(String cmd) async {
      await tester.enterText(find.byType(TextField), cmd);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
    }

    // 무료 사용자는 제목줄에 PRO 링크가 있고, amber 테마가 거부된다.
    expect(find.text('PRO'), findsOneWidget);
    await type('theme amber');
    expect(find.text('Access is denied.'), findsOneWidget);
    expect(store.palette.id, 'cmd');

    // upgrade → PRO 화면
    await type('upgrade');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('todo.exe PRO'), findsOneWidget);
    expect(find.text('스토어에 연결되지 않았어요.'), findsOneWidget);

    await tester.tap(find.text('구매하기'));
    await tester.pump();
    expect(find.textContaining('스토어에 연결할 수 없어요'), findsOneWidget);

    await tester.tap(find.text('[ ESC ] 닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 디버그 빌드 전용 명령으로 PRO 를 켜면 테마를 바꿀 수 있고 PRO 링크가 사라진다.
    await type('pro --dev');
    expect(store.isPro, isTrue);
    await type('theme amber');
    expect(store.palette.id, 'amber');
    expect(find.text('PRO'), findsNothing);
  });

  testWidgets('처음 실행: 사용법 안내 4장 → 시작하기 → 다음부터는 안 보임', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final store = TodoStore(clock: () => DateTime(2026, 9, 29, 13));
    await store.load();
    expect(store.onboarded, isFalse);

    await tester.pumpWidget(TodoExeApp(store: store));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('명령어로 쓰는'), findsOneWidget);
    expect(find.text('[■□□□] 1/4'), findsOneWidget);
    for (var i = 2; i <= 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('$i/4'), findsOneWidget);
    }
    expect(find.text('기록과 도움말'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('이 줄을 탭하면 완료돼요'), findsOneWidget);
    expect(store.onboarded, isTrue);

    // 앱을 다시 켜면 안내 없이 바로 목록.
    final again = TodoStore(clock: () => DateTime(2026, 9, 29, 13));
    await again.load();
    expect(again.onboarded, isTrue);
  });

  test('예전부터 쓰던 사람(저장된 할 일이 있음)은 안내를 건너뛴다', () async {
    SharedPreferences.setMockInitialValues({'todo_exe_state_v1': '{"tasks":[],"completions":[],"nextId":1}'});
    final store = TodoStore(clock: () => DateTime(2026, 9, 29, 13));
    await store.load();
    expect(store.onboarded, isTrue);
  });
}
