import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/stats.dart';
import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';
import 'help_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.store});

  final TodoStore store;

  @override
  Widget build(BuildContext context) {
    final p = store.palette;
    final now = store.now();
    final s = Stats.compute(store.data, now);
    final dayMax = s.last7.fold<int>(0, (m, e) => math.max(m, e.count));
    final tagMax = s.tags.isEmpty ? 0 : s.tags.first.count;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleBar(
            palette: p,
            now: now,
            active: 'stats',
            onHelp: () => Navigator.of(context).pushReplacement(termRoute(HelpScreen(store: store))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim)),
                  TextSpan(text: 'stats --week', style: termStyle(p.cmd)),
                ])),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: p.line)),
                  child: Column(
                    children: [
                      _KeyValue(palette: p, k: '현재 목록', v: '${s.done} / ${s.total}', extra: '${s.pct}%', extraColor: p.ok),
                      _KeyValue(palette: p, k: '이번 주 완료', v: '${s.weekTotal}건'),
                      _KeyValue(palette: p, k: '연속 달성', v: '${s.streak}일', extra: '최고 ${s.bestStreak}일'),
                      _KeyValue(
                        palette: p,
                        k: '최다 태그',
                        v: s.tags.isEmpty ? '-' : _tagLabel(s.tags.first.tag),
                        vColor: p.tag,
                        extra: s.tags.isEmpty ? null : '${s.tags.first.count}건',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _Heading(palette: p, text: '지난 7일'),
                for (final e in s.last7)
                  _BarRow(
                    palette: p,
                    label: shortDate(e.day),
                    labelColor: dayOf(e.day) == dayOf(now) ? p.hi : p.dim,
                    bar: textBar(e.count, dayMax),
                    barColor: p.ok,
                    value: '${e.count}',
                    note: dayOf(e.day) == dayOf(now) ? '◀ 오늘' : null,
                  ),
                const SizedBox(height: 20),
                _Heading(palette: p, text: '태그별 완료'),
                if (s.tags.isEmpty)
                  Text('아직 완료 기록이 없어요.', style: termStyle(p.dim, size: 13))
                else
                  for (final t in s.tags)
                    _BarRow(
                      palette: p,
                      label: _tagLabel(t.tag),
                      labelColor: p.tag,
                      bar: textBar(t.count, tagMax),
                      barColor: p.cmd,
                      value: '${t.count}',
                    ),
                const SizedBox(height: 20),
                _Heading(palette: p, text: '최근 4주'),
                _Heatmap(palette: p, stats: s, today: dayOf(now)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '적음 ', style: termStyle(p.dim, size: 12)),
                  TextSpan(text: '·', style: termStyle(p.line, size: 12)),
                  TextSpan(text: ' ░ ▒ ▓ █ ', style: termStyle(p.ok, size: 12)),
                  TextSpan(text: '많음', style: termStyle(p.dim, size: 12)),
                ])),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TermWideButton(
                palette: p,
                keyLabel: '[ ESC ]',
                label: '목록으로',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _tagLabel(String tag) => tag == '-' ? '(태그 없음)' : '#$tag';
}

class _Heading extends StatelessWidget {
  const _Heading({required this.palette, required this.text});

  final TermPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: termStyle(palette.hi)),
      );
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.palette,
    required this.k,
    required this.v,
    this.vColor,
    this.extra,
    this.extraColor,
  });

  final TermPalette palette;
  final String k;
  final String v;
  final Color? vColor;
  final String? extra;
  final Color? extraColor;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(k, style: termStyle(p.dim))),
          Text(v, style: termStyle(vColor ?? p.hi)),
          if (extra != null) ...[
            const SizedBox(width: 10),
            Text(extra!, style: termStyle(extraColor ?? p.dim)),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.palette,
    required this.label,
    required this.labelColor,
    required this.bar,
    required this.barColor,
    required this.value,
    this.note,
  });

  final TermPalette palette;
  final String label;
  final Color labelColor;
  final String bar;
  final Color barColor;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: termStyle(labelColor, size: 13)),
          ),
          Text(bar, style: termStyle(barColor, size: 13)),
          const SizedBox(width: 12),
          Text(value, style: termStyle(p.fg, size: 13)),
          if (note != null) ...[
            const SizedBox(width: 10),
            Text(note!, style: termStyle(p.tag, size: 13)),
          ],
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.palette, required this.stats, required this.today});

  final TermPalette palette;
  final Stats stats;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final style = termStyle(p.dim, size: 13);
    return Semantics(
      label: '최근 4주 하루별 완료량. 연속 달성 ${stats.streak}일.',
      excludeSemantics: true,
      child: Table(
        columnWidths: const {0: FixedColumnWidth(52)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            const SizedBox(height: 24),
            for (final w in weekdayKo) Center(child: Text(w, style: style)),
          ]),
          for (var r = 0; r < 4; r++)
            TableRow(children: [
              SizedBox(
                height: 26,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(() {
                    final d = addDays(stats.heatStart, r * 7);
                    return '${two(d.month)}.${two(d.day)}';
                  }(), style: style),
                ),
              ),
              for (var c = 0; c < 7; c++) _cell(p, r, c),
            ]),
        ],
      ),
    );
  }

  Widget _cell(TermPalette p, int r, int c) {
    final count = stats.heat[r][c];
    final day = addDays(stats.heatStart, r * 7 + c);
    final isToday = day == today;
    return Container(
      height: 24,
      margin: const EdgeInsets.all(1),
      alignment: Alignment.center,
      decoration: isToday ? BoxDecoration(border: Border.all(color: p.hi)) : null,
      child: count == null
          ? const SizedBox.shrink()
          : Text(heatGlyph(count), style: termStyle(count == 0 ? p.line : p.ok, size: 14, height: 1)),
    );
  }
}
