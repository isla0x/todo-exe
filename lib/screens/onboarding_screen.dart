import 'package:flutter/material.dart';

import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';
import 'home_screen.dart';

/// 한 장: 제목 · 터미널 예시 줄 · 설명
class _Page {
  const _Page(this.title, this.lines, this.body);

  final String title;

  /// (종류, 글) — in: 입력한 명령어, ok: 결과, row: 목록 한 줄, hi: 강조
  final List<(String, String)> lines;
  final String body;
}

const _pages = [
  _Page('명령어로 쓰는\n할 일 목록', [
    ('in', '운동 30분'),
    ('ok', '+ #05 추가됨'),
  ], '아래 입력창에 할 일을 쓰고 Enter.\n명령어 없이 써도 바로 추가돼요.'),
  _Page('#태그와 ! 중요도', [
    ('in', 'add 보고서 초안 #work !!'),
    ('ok', '+ #06 추가됨'),
    ('row', '[ ] #06 보고서 초안  !! #work'),
  ], '#태그로 묶고, ! 개수(! · !! · !!!)로\n급한 정도를 표시해요.'),
  _Page('끝낸 일은 done', [
    ('in', 'done 6'),
    ('ok', '✓ #06 완료'),
    ('in', 'edit 5 운동 1시간'),
    ('in', 'rm 5'),
  ], '목록에서 줄을 탭해도 완료돼요.\n고치기는 edit, 지우기는 rm.'),
  _Page('기록과 도움말', [
    ('in', 'stats'),
    ('hi', '연속 달성 3일 · 이번 주 12건'),
    ('in', 'help'),
  ], 'stats 로 연속 달성과 4주 잔디를,\nhelp 로 모든 명령어를 볼 수 있어요.\n입력창 위 버튼을 눌러도 돼요.'),
];

/// 처음 실행했을 때 한 번 보여주는 사용법 안내. help 화면에서 다시 볼 수 있다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store, this.replay = false});

  final TodoStore store;

  /// help 에서 다시 보는 중이면 끝났을 때 이전 화면으로 돌아간다.
  final bool replay;

  static int get pageCount => _pages.length;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  TodoStore get store => widget.store;
  bool get _last => _page == _pages.length - 1;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await store.markOnboarded();
    if (!mounted) return;
    if (widget.replay) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).pushReplacement(termRoute(HomeScreen(store: store)));
    }
  }

  void _next() {
    if (_last) {
      _finish();
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = store.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleBar(palette: p, now: store.now()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim, size: 13)),
                  TextSpan(text: 'intro', style: termStyle(p.cmd, size: 13)),
                ])),
                const Spacer(),
                Semantics(
                  label: '${_page + 1} / ${_pages.length} 페이지',
                  excludeSemantics: true,
                  child: Text(
                    '[${'■' * (_page + 1)}${'□' * (_pages.length - _page - 1)}] ${_page + 1}/${_pages.length}',
                    style: termStyle(p.ok, size: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _PageView(page: _pages[i], palette: p),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TermWideButton(
                    palette: p,
                    keyLabel: '[ ENTER ]',
                    label: _last ? '시작하기' : '다음',
                    onTap: _next,
                    trailing: _last ? BlinkingCursor(style: termStyle(p.hi, size: 15)) : null,
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _last ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: _last,
                      child: TermBoxButton(palette: p, label: '[ ESC ] 건너뛰기', onTap: _finish),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page, required this.palette});

  final _Page page;
  final TermPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(page.title, style: termStyle(p.hi, size: 26, weight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: p.bar, border: Border.all(color: p.line)),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (kind, text) in page.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: switch (kind) {
                      'in' => Text.rich(TextSpan(children: [
                          TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim, size: 14)),
                          TextSpan(text: text, style: termStyle(p.cmd, size: 14)),
                        ])),
                      'ok' => Text(text, style: termStyle(p.ok, size: 14)),
                      'row' => Text(text, style: termStyle(p.hi, size: 14)),
                      _ => Text(text, style: termStyle(p.tag, size: 14)),
                    },
                  ),
                Row(
                  children: [
                    Text('C:\\todo> ', style: termStyle(p.dim, size: 14)),
                    BlinkingCursor(style: termStyle(p.ok, size: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(page.body, style: termStyle(p.fg, size: 15, height: 1.7)),
        ],
      ),
    );
  }
}
