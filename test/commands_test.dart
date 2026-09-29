import 'package:flutter_test/flutter_test.dart';
import 'package:todo_exe/logic/commands.dart';
import 'package:todo_exe/models/task.dart';

void main() {
  final now = DateTime(2026, 9, 29, 13, 0);

  TodoData empty() => const TodoData(tasks: [], completions: [], nextId: 1);

  TodoData run(TodoData d, String cmd) => runCommand(d, cmd, now).data;

  group('parseTaskInput', () {
    test('태그와 우선순위를 분리한다', () {
      final p = parseTaskInput('보고서 초안 #work !!');
      expect(p.text, '보고서 초안');
      expect(p.tag, 'work');
      expect(p.priority, 2);
    });

    test('문장 중간의 느낌표는 우선순위가 아니다', () {
      final p = parseTaskInput('와! 주말이다');
      expect(p.text, '와! 주말이다');
      expect(p.priority, 0);
    });

    test('태그만 있으면 원문을 텍스트로 쓴다', () {
      expect(parseTaskInput('#work').text, '#work');
    });
  });

  group('runCommand', () {
    test('add 는 번호를 붙여 추가한다', () {
      final d = run(empty(), 'add 운동 30분 #health !');
      expect(d.tasks, hasLength(1));
      expect(d.tasks.single.id, 1);
      expect(d.tasks.single.text, '운동 30분');
      expect(d.tasks.single.tag, 'health');
      expect(d.tasks.single.priority, 1);
      expect(d.nextId, 2);
    });

    test('모르는 명령어는 통째로 할 일이 된다', () {
      final d = run(empty(), '우유 사기');
      expect(d.tasks.single.text, '우유 사기');
    });

    test('done 과 undo 는 완료 기록도 함께 바꾼다', () {
      var d = run(empty(), 'add 책 읽기 #life');
      d = run(d, 'done 1');
      expect(d.tasks.single.done, isTrue);
      expect(d.completions, hasLength(1));
      expect(d.completions.single.tag, 'life');

      d = run(d, 'undo #01');
      expect(d.tasks.single.done, isFalse);
      expect(d.completions, isEmpty);
    });

    test('없는 번호는 에러 로그를 남긴다', () {
      final out = runCommand(empty(), 'done 9', now);
      expect(out.lines.last.kind, LogKind.err);
    });

    test('edit 는 태그를 안 쓰면 기존 태그를 유지한다', () {
      var d = run(empty(), 'add 운동 #health !!');
      d = run(d, 'edit 1 운동 1시간');
      expect(d.tasks.single.text, '운동 1시간');
      expect(d.tasks.single.tag, 'health');
      expect(d.tasks.single.priority, 2);

      d = run(d, 'edit 1 산책 #walk');
      expect(d.tasks.single.tag, 'walk');
    });

    test('rm 은 삭제해도 완료 기록은 남긴다', () {
      var d = run(empty(), 'add a');
      d = run(d, 'done 1');
      d = run(d, 'rm 1');
      expect(d.tasks, isEmpty);
      expect(d.completions, hasLength(1));
    });

    test('ls 필터', () {
      var d = run(empty(), 'add a #x');
      d = run(d, 'add b #y');
      d = run(d, 'done 2');
      expect(run(d, 'ls --todo').filter, TaskFilter.todo);
      expect(run(d, 'ls --done').filter, TaskFilter.done);
      final tagged = run(d, 'ls #x');
      expect(tagged.filter.kind, FilterKind.tag);
      expect(tagged.tasks.where(tagged.filter.matches).map((t) => t.text), ['a']);
      expect(run(tagged, 'ls').filter, TaskFilter.all);
    });

    test('clear 는 완료 항목만 지운다', () {
      var d = run(empty(), 'add a');
      d = run(d, 'add b');
      d = run(d, 'done 1');
      d = run(d, 'clear');
      expect(d.tasks.map((t) => t.text), ['b']);
    });

    test('cls 는 로그만 지운다', () {
      final d = run(empty(), 'add a');
      final out = runCommand(d, 'cls', now);
      expect(out.clearLog, isTrue);
      expect(out.data.tasks, hasLength(1));
    });

    test('theme 와 crt', () {
      var d = run(empty(), 'theme amber');
      expect(d.theme, 'amber');
      d = run(d, 'theme nope');
      expect(d.theme, 'amber');
      d = run(d, 'crt on');
      expect(d.crt, isTrue);
      d = run(d, 'crt');
      expect(d.crt, isFalse);
    });

    test('stats 는 화면 이동을 요청한다', () {
      expect(runCommand(empty(), 'stats', now).route, 'stats');
    });
  });

  test('JSON 저장/복원', () {
    var d = run(empty(), 'add 보고서 #work !!');
    d = run(d, 'done 1');
    d = run(d, 'theme phosphor');
    final back = TodoData.fromJson(d.toJson());
    expect(back.tasks.single.text, '보고서');
    expect(back.tasks.single.done, isTrue);
    expect(back.tasks.single.doneAt, now);
    expect(back.completions.single.at, now);
    expect(back.nextId, 2);
    expect(back.theme, 'phosphor');
  });

  test('Task.withDone 은 doneAt 을 관리한다', () {
    final t = Task(id: 1, text: 'a', createdAt: now);
    expect(t.withDone(true, now).doneAt, now);
    expect(t.withDone(true, now).withDone(false, now).doneAt, isNull);
  });
}
