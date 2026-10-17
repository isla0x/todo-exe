import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';
import 'stats_screen.dart';

/// 도움말에 나오는 명령어 순서. 설명은 l10n 표의 `h.<명령어>.a`(인자) · `.d`(설명) · `.e`(예시).
const _commands = [
  'add', 'done', 'undo', 'edit', 'rm', 'ls', 'clear', 'cls', 'stats', 'theme', 'mode', 'lang', 'crt', 'upgrade', 'restore', //
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
                Text(tr('help.title'), style: termStyle(p.hi)),
                Text(tr('help.legend'), style: termStyle(p.dim, size: 13)),
                const SizedBox(height: 10),
                DashedDivider(color: p.line),
                for (final cmd in _commands)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: cmd, style: termStyle(p.cmd)),
                          if (trHas('h.$cmd.a')) TextSpan(text: ' ${tr('h.$cmd.a')}', style: termStyle(p.fg)),
                        ])),
                        const SizedBox(height: 2),
                        Text(tr('h.$cmd.d'), style: termStyle(p.dim, size: 13)),
                        if (trHas('h.$cmd.e')) Text(tr('help.ex', {'e': tr('h.$cmd.e')}), style: termStyle(p.tag, size: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text(tr('help.syntax'), style: termStyle(p.hi)),
                const SizedBox(height: 6),
                _SyntaxRow(palette: p, token: '! !! !!!', tokenColor: p.warn, text: tr('help.sx.pri')),
                _SyntaxRow(palette: p, token: tr('help.sx.tagtok'), tokenColor: p.tag, text: tr('help.sx.tag')),
                _SyntaxRow(palette: p, token: '#03', tokenColor: p.dim, text: tr('help.sx.num')),
                _SyntaxRow(palette: p, token: '↑ ↓', tokenColor: p.hi, text: tr('help.sx.hist')),
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
                label: tr('btn.back'),
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
