import 'package:flutter/material.dart';

import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';
import 'onboarding_screen.dart';
import 'stats_screen.dart';

/// (명령어, 인자, 설명, 예시)
const _entries = <(String, String, String, String?)>[
  ('add', '<할 일> [#태그] [!]', '새 할 일 추가. 명령어 없이 입력해도 add로 처리돼요.', 'add 보고서 초안 #work !!'),
  ('done', '<번호>', '완료 처리. 목록에서 줄을 탭해도 같아요.', 'done 3'),
  ('undo', '<번호>', '완료를 취소하고 다시 할 일로 돌려놔요.', null),
  ('edit', '<번호> <내용>', '내용 수정. #태그나 !를 쓰면 함께 바뀌어요.', 'edit 2 운동 1시간 #health'),
  ('rm', '<번호>', '삭제. 줄 오른쪽 rm 버튼과 같아요.', null),
  ('ls', '[--todo | --done | #태그]', '목록 필터. 인자 없이 쓰면 전체 보기.', 'ls #work'),
  ('clear', '', '완료된 항목을 한 번에 정리해요. 통계 기록은 남아요.', null),
  ('cls', '', '화면 로그만 지워요. 할 일은 그대로예요.', null),
  ('stats', '', '완료 기록, 연속 달성일, 태그별 통계.', null),
  ('theme', '[cmd | phosphor | amber]', '색 테마 변경. phosphor · amber 는 PRO.', 'theme amber'),
  ('mode', '[auto | light | dark]', '밝기 모드. auto 는 폰 설정을 따라가요. (cmd 테마)', 'mode light'),
  ('crt', '[on | off]', '옛날 모니터 같은 주사선 효과. (PRO)', null),
  ('upgrade', '', 'PRO 소개와 구매. 테마 · CRT · 위젯(iPhone)을 한 번 결제로 열어요.', null),
  ('restore', '', '예전에 산 PRO 를 다시 불러와요. (기기 변경, 재설치)', null),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.store});

  final TodoStore store;

  @override
  Widget build(BuildContext context) {
    final p = store.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleBar(
            palette: p,
            now: store.now(),
            active: 'help',
            onStats: () => Navigator.of(context).pushReplacement(termRoute(StatsScreen(store: store))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim)),
                  TextSpan(text: 'help', style: termStyle(p.cmd)),
                ])),
                const SizedBox(height: 10),
                Text('명령어 목록', style: termStyle(p.hi)),
                Text('<필수>  [선택]  |  또는', style: termStyle(p.dim, size: 13)),
                const SizedBox(height: 10),
                TermBoxButton(
                  palette: p,
                  label: '처음 사용법 안내 다시 보기',
                  onTap: () => Navigator.of(context).push(termRoute(OnboardingScreen(store: store, replay: true))),
                ),
                const SizedBox(height: 10),
                DashedDivider(color: p.line),
                for (final e in _entries)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: e.$1, style: termStyle(p.cmd)),
                          if (e.$2.isNotEmpty) TextSpan(text: ' ${e.$2}', style: termStyle(p.fg)),
                        ])),
                        const SizedBox(height: 2),
                        Text(e.$3, style: termStyle(p.dim, size: 13)),
                        if (e.$4 != null) Text('예) ${e.$4}', style: termStyle(p.tag, size: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text('문법', style: termStyle(p.hi)),
                const SizedBox(height: 6),
                _SyntaxRow(palette: p, token: '! !! !!!', tokenColor: p.warn, text: '우선순위 1~3'),
                _SyntaxRow(palette: p, token: '#태그', tokenColor: p.tag, text: '첫 번째 태그만 인식'),
                _SyntaxRow(palette: p, token: '#03', tokenColor: p.dim, text: '번호는 3 처럼 앞 0 생략 가능'),
                _SyntaxRow(palette: p, token: '↑ ↓', tokenColor: p.hi, text: '이전 명령어 (키보드 연결 시)'),
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
}

class _SyntaxRow extends StatelessWidget {
  const _SyntaxRow({required this.palette, required this.token, required this.tokenColor, required this.text});

  final TermPalette palette;
  final String token;
  final Color tokenColor;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 76, child: Text(token, style: termStyle(tokenColor, size: 13))),
            Expanded(child: Text(text, style: termStyle(palette.dim, size: 13))),
          ],
        ),
      );
}
