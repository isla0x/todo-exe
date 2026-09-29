import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_exe/main.dart';
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
  });
}
