import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/commands.dart';
import '../models/task.dart';
import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';
import 'help_screen.dart';
import 'stats_screen.dart';

/// 메인 화면: 할 일 목록 + 명령어 입력창.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final TodoStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  int? _histIdx;

  TodoStore get store => widget.store;

  static const _chips = ['add', 'done', 'edit', 'rm', 'clear', 'cls', 'help'];
  static const _prefillChips = {'add', 'done', 'edit', 'rm'};

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _run(String raw, {bool fromInput = false}) {
    if (raw.trim().isEmpty) return;
    final before = store.data.nextId;
    final route = store.run(raw);
    if (fromInput) _ctrl.clear();
    _histIdx = null;
    if (store.data.nextId != before) _scrollToEnd();
    if (route != null) _open(route);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _open(String route) {
    final page = route == 'stats' ? StatsScreen(store: store) : HelpScreen(store: store);
    Navigator.of(context).push(termRoute(page));
  }

  void _prefill(String cmd) {
    _ctrl.value = TextEditingValue(
      text: '$cmd ',
      selection: TextSelection.collapsed(offset: cmd.length + 1),
    );
    _focus.requestFocus();
  }

  /// 하드웨어 키보드 ↑ ↓ 로 이전 명령어 불러오기.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final up = e.logicalKey == LogicalKeyboardKey.arrowUp;
    final down = e.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!up && !down) return KeyEventResult.ignored;
    final h = store.history;
    if (h.isEmpty) return KeyEventResult.ignored;
    final cur = _histIdx ?? h.length;
    final i = up ? math.max(0, cur - 1) : math.min(h.length, cur + 1);
    _histIdx = i;
    final text = i == h.length ? '' : h[i];
    _ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    return KeyEventResult.handled;
  }

  Color _logColor(TermPalette p, LogKind k) => switch (k) {
        LogKind.cmd => p.fg,
        LogKind.ok => p.ok,
        LogKind.err => p.warn,
        LogKind.info => p.dim,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.palette;
        final d = store.data;
        final visible = d.tasks.where(d.filter.matches).toList();
        final total = d.tasks.length;
        final done = d.doneCount;
        final pct = total == 0 ? 0 : (done * 100 / total).round();
        final cells = total == 0 ? 0 : (done * 10 / total).round();

        Widget filterButton(TaskFilter f, String name, int count) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TermBoxButton(
                palette: p,
                label: '--$name $count',
                selected: d.filter == f,
                onTap: () => _run(f == TaskFilter.all ? 'ls' : 'ls --$name'),
              ),
            );

        return Scaffold(
          backgroundColor: p.bg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleBar(
                palette: p,
                now: store.now(),
                onStats: () => _open('stats'),
                onHelp: () => _open('help'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('TODO [Version 1.0.0]', style: termStyle(p.hi)),
                      Text('(c) 채은. 오늘도 하나씩, 천천히.', style: termStyle(p.dim, size: 13)),
                      const SizedBox(height: 12),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim)),
                        TextSpan(text: 'ls ${d.filter.flag}'.trimRight(), style: termStyle(p.cmd)),
                      ])),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            filterButton(TaskFilter.all, 'all', total),
                            filterButton(TaskFilter.todo, 'todo', total - done),
                            filterButton(TaskFilter.done, 'done', done),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text('진행', style: termStyle(p.dim, size: 13)),
                          const SizedBox(width: 10),
                          Text('[${'█' * cells}${'░' * (10 - cells)}]', style: termStyle(p.ok, size: 13)),
                          const SizedBox(width: 10),
                          Text('$done/$total', style: termStyle(p.hi, size: 13)),
                          const SizedBox(width: 10),
                          Text('$pct%', style: termStyle(p.dim, size: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DashedDivider(color: p.line),
                      Expanded(
                        child: visible.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text.rich(TextSpan(children: [
                                  TextSpan(text: '표시할 항목이 없습니다. ', style: termStyle(p.dim)),
                                  TextSpan(text: 'add', style: termStyle(p.cmd)),
                                  TextSpan(text: ' 로 추가해 보세요.', style: termStyle(p.dim)),
                                ])),
                              )
                            : ListView.builder(
                                controller: _scroll,
                                padding: EdgeInsets.zero,
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: visible.length,
                                itemBuilder: (context, i) {
                                  final t = visible[i];
                                  return _TaskRow(
                                    key: ValueKey(t.id),
                                    task: t,
                                    palette: p,
                                    onToggle: () => _run('${t.done ? 'undo' : 'done'} ${t.id}'),
                                    onRemove: () => _run('rm ${t.id}'),
                                  );
                                },
                              ),
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final l in store.log)
                                Text(l.text, style: termStyle(_logColor(p, l.kind), size: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _footer(p),
            ],
          ),
        );
      },
    );
  }

  Widget _footer(TermPalette p) {
    // 이 영역 안의 탭(칩, 실행 버튼)은 '입력창 밖'으로 치지 않아 키보드가 유지된다.
    return TextFieldTapRegion(child: _footerBody(p));
  }

  Widget _footerBody(TermPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.bar,
        border: Border(top: BorderSide(color: p.line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in _chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TermBoxButton(
                        palette: p,
                        label: c,
                        textColor: p.cmd,
                        onTap: () => _prefillChips.contains(c) ? _prefill(c) : _run(c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.only(left: 12, right: 2),
              decoration: BoxDecoration(color: p.bg, border: Border.all(color: p.line)),
              child: Row(
                children: [
                  Text('C:\\todo>', style: termStyle(p.hi)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Focus(
                      onKeyEvent: _onKey,
                      child: Semantics(
                        label: '명령어 입력',
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          style: termStyle(p.hi, size: 16, height: 1.2),
                          cursorColor: p.ok,
                          cursorWidth: 9,
                          cursorHeight: 18,
                          autocorrect: false,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration.collapsed(
                            hintText: 'add 할 일 #태그 !',
                            hintStyle: termStyle(p.dim, size: 16, height: 1.2),
                          ),
                          onChanged: (_) => _histIdx = null,
                          // 입력 영역(칩, 실행 버튼 포함) 밖을 탭하면 키보드를 내린다.
                          onTapOutside: (_) => _focus.unfocus(),
                          onSubmitted: (v) => _run(v, fromInput: true),
                          // 비워두면 Enter 후에도 키보드가 닫히지 않는다.
                          onEditingComplete: () {},
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: '실행',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () {
                        _run(_ctrl.text, fromInput: true);
                        _focus.requestFocus();
                      },
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: CustomPaint(size: const Size(18, 18), painter: ReturnIconPainter(p.ok)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.task,
    required this.palette,
    required this.onToggle,
    required this.onRemove,
  });

  final Task task;
  final TermPalette palette;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final t = task;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              checked: t.done,
              label: '${t.done ? '완료 취소' : '완료 표시'}: ${t.text}',
              excludeSemantics: true,
              child: InkWell(
                onTap: onToggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(t.done ? '[x]' : '[ ]', style: termStyle(t.done ? p.ok : p.fg)),
                        const SizedBox(width: 10),
                        Text(taskNum(t.id), style: termStyle(p.dim, size: 12)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: termStyle(
                              t.done ? p.dim : p.hi,
                              decoration: t.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (t.priority > 0) ...[
                          const SizedBox(width: 8),
                          Text('!' * t.priority, style: termStyle(p.warn, weight: FontWeight.w700)),
                        ],
                        if (t.tag.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Text(
                              '#${t.tag}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: termStyle(p.tag, size: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '삭제: ${t.text}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onRemove,
              child: SizedBox(
                width: 44,
                height: 48,
                child: Center(child: Text('rm', style: termStyle(p.dim, size: 12))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
