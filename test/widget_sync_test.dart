import 'package:flutter_test/flutter_test.dart';
import 'package:todo_exe/logic/commands.dart';
import 'package:todo_exe/widget_sync.dart';

void main() {
  final now = DateTime(2026, 9, 29, 13);

  TodoData run(TodoData d, String cmd) => runCommand(d, cmd, now).data;

  test('위젯 스냅샷: 남은 할 일을 우선순위 → 번호 순으로 담는다', () {
    var d = const TodoData(tasks: [], completions: [], nextId: 1);
    d = run(d, 'add 책 읽기 #life');
    d = run(d, 'add 보고서 #work !!');
    d = run(d, 'add 장보기');
    d = run(d, 'add 운동 !');
    d = run(d, 'done 3');
    d = runCommand(d, 'theme amber', now, pro: true).data;

    final s = widgetSnapshot(d, now, pro: true);
    expect(s['pro'], isTrue);
    expect(s['theme'], 'amber');
    expect(s['done'], 1);
    expect(s['total'], 4);
    expect(s['streak'], 1);

    final todo = (s['todo'] as List).cast<Map<String, dynamic>>();
    expect(todo.map((e) => e['t']), ['보고서', '운동', '책 읽기']);
    expect(todo.first, {'n': '#02', 't': '보고서', 'p': 2, 'g': 'work'});
  });

  test('PRO 가 아니면 pro=false, 테마는 cmd 로 고정', () {
    var d = const TodoData(tasks: [], completions: [], nextId: 1, theme: 'amber');
    d = run(d, 'add 책 읽기');
    final s = widgetSnapshot(d, now);
    expect(s['pro'], isFalse);
    expect(s['theme'], 'cmd');
    expect((s['todo'] as List).length, 1);
  });

  test('위젯 스냅샷은 최대 개수만큼만 담는다', () {
    var d = const TodoData(tasks: [], completions: [], nextId: 1);
    for (var i = 0; i < 12; i++) {
      d = run(d, 'add 할 일 $i');
    }
    expect((widgetSnapshot(d, now)['todo'] as List).length, 8);
  });
}
