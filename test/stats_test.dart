import 'package:flutter_test/flutter_test.dart';
import 'package:todo_exe/logic/commands.dart';
import 'package:todo_exe/logic/stats.dart';
import 'package:todo_exe/models/task.dart';

void main() {
  // 2026-09-29 는 화요일
  final now = DateTime(2026, 9, 29, 13);

  Completion c(int daysAgo, [String tag = 'work']) =>
      Completion(taskId: daysAgo, tag: tag, at: DateTime(2026, 9, 29 - daysAgo, 10));

  TodoData withCompletions(List<Completion> cs) => TodoData(tasks: const [], completions: cs, nextId: 1);

  test('오늘 포함 연속 달성일', () {
    final s = Stats.compute(withCompletions([c(0), c(1), c(2), c(4)]), now);
    expect(s.streak, 3);
    expect(s.bestStreak, 3);
  });

  test('오늘 아직 안 했으면 어제까지의 연속을 유지한다', () {
    final s = Stats.compute(withCompletions([c(1), c(2)]), now);
    expect(s.streak, 2);
  });

  test('이틀 이상 비면 연속이 끊긴다', () {
    final s = Stats.compute(withCompletions([c(2), c(3)]), now);
    expect(s.streak, 0);
    expect(s.bestStreak, 2);
  });

  test('최근 7일과 태그 집계', () {
    final s = Stats.compute(withCompletions([c(0), c(0, 'life'), c(6), c(7)]), now);
    expect(s.last7, hasLength(7));
    expect(s.last7.last.count, 2);
    expect(s.last7.first.count, 1);
    expect(s.weekTotal, 3);
    expect(s.tags.first.tag, 'work');
    expect(s.tags.first.count, 3);
  });

  test('잔디는 4주 전 월요일부터, 미래는 비운다', () {
    final s = Stats.compute(withCompletions([c(0)]), now);
    expect(s.heatStart, DateTime(2026, 9, 7));
    expect(s.heatStart.weekday, DateTime.monday);
    expect(s.heat[3][1], 1); // 이번 주 화요일 = 오늘
    expect(s.heat[3][2], isNull); // 내일
  });

  test('막대와 잔디 문자', () {
    expect(textBar(5, 10), '█████░░░░░');
    expect(textBar(3, 0), '░░░░░░░░░░');
    expect(heatGlyph(0), '·');
    expect(heatGlyph(6), '█');
    expect(shortDate(now), '09.29 화');
  });
}
