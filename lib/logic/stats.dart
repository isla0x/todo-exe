import 'dart:math' as math;

import 'commands.dart';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime addDays(DateTime day, int n) => DateTime(day.year, day.month, day.day + n);

class DayCount {
  const DayCount(this.day, this.count);

  final DateTime day;
  final int count;
}

class TagCount {
  const TagCount(this.tag, this.count);

  final String tag;
  final int count;
}

/// stats 화면에 필요한 숫자들.
class Stats {
  Stats._({
    required this.total,
    required this.done,
    required this.streak,
    required this.bestStreak,
    required this.weekTotal,
    required this.last7,
    required this.tags,
    required this.heatStart,
    required this.heat,
  });

  /// 현재 목록 기준.
  final int total;
  final int done;

  /// 오늘(또는 어제)까지 하루도 빠짐없이 1개 이상 완료한 날 수.
  final int streak;
  final int bestStreak;

  /// 최근 7일 완료 수.
  final int weekTotal;
  final List<DayCount> last7;

  /// 완료 기록 기준 태그별 개수, 많은 순.
  final List<TagCount> tags;

  /// 4주 전 월요일.
  final DateTime heatStart;

  /// 4행(주) × 7열(월~일). 미래 날짜는 null.
  final List<List<int?>> heat;

  int get pct => total == 0 ? 0 : (done * 100 / total).round();

  factory Stats.compute(TodoData d, DateTime now) {
    final today = dayOf(now);
    final byDay = <DateTime, int>{};
    final byTag = <String, int>{};
    for (final c in d.completions) {
      byDay.update(dayOf(c.at), (v) => v + 1, ifAbsent: () => 1);
      final tag = c.tag.isEmpty ? '-' : c.tag;
      byTag.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }

    var cur = (byDay[today] ?? 0) > 0 ? today : addDays(today, -1);
    var streak = 0;
    while ((byDay[cur] ?? 0) > 0) {
      streak++;
      cur = addDays(cur, -1);
    }

    final days = byDay.keys.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final day in days) {
      run = (prev != null && addDays(prev, 1) == day) ? run + 1 : 1;
      best = math.max(best, run);
      prev = day;
    }

    final last7 = [
      for (var i = 6; i >= 0; i--) DayCount(addDays(today, -i), byDay[addDays(today, -i)] ?? 0),
    ];

    final tags = [for (final e in byTag.entries) TagCount(e.key, e.value)]
      ..sort((a, b) => b.count.compareTo(a.count));

    final monday = addDays(today, -(today.weekday - 1));
    final heatStart = addDays(monday, -21);
    final heat = [
      for (var r = 0; r < 4; r++)
        [
          for (var c = 0; c < 7; c++)
            () {
              final day = addDays(heatStart, r * 7 + c);
              return day.isAfter(today) ? null : (byDay[day] ?? 0);
            }(),
        ],
    ];

    return Stats._(
      total: d.tasks.length,
      done: d.doneCount,
      streak: streak,
      bestStreak: math.max(best, streak),
      weekTotal: last7.fold(0, (sum, e) => sum + e.count),
      last7: last7,
      tags: tags.take(5).toList(),
      heatStart: heatStart,
      heat: heat,
    );
  }
}

/// `████░░░░░░` 형태의 막대. [max]가 0이면 빈 막대.
String textBar(int value, int max, {int width = 10}) {
  final cells = max <= 0 ? 0 : math.min(width, math.max(0, (value * width / max).round()));
  return '█' * cells + '░' * (width - cells);
}

/// 잔디 칸 모양.
String heatGlyph(int count) {
  if (count <= 0) return '·';
  if (count == 1) return '░';
  if (count <= 3) return '▒';
  if (count <= 5) return '▓';
  return '█';
}

const weekdayKo = ['월', '화', '수', '목', '금', '토', '일'];

String two(int n) => n.toString().padLeft(2, '0');

/// `09.29 화`
String shortDate(DateTime d) => '${two(d.month)}.${two(d.day)} ${weekdayKo[d.weekday - 1]}';
