import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../pro/pro_controller.dart';
import '../state/todo_store.dart';
import '../theme/term_palette.dart';
import '../widgets/term_widgets.dart';

/// `upgrade` 화면: PRO 소개 + 구매 / 복원.
class ProScreen extends StatelessWidget {
  const ProScreen({super.key, required this.store});

  final TodoStore store;

  /// 위젯은 iOS 에만 있다 (안드로이드는 테마 · CRT 만).
  static bool get _hasWidgets => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static List<(String, String)> get _features => [
        for (final f in _allFeatures)
          if (_hasWidgets || !f.$2) (tr('${f.$1}.t'), tr('${f.$1}.s')),
      ];

  /// (l10n 키, 위젯 기능인지)
  static const _allFeatures = [
    ('pro.f1', false),
    ('pro.f2', true),
    ('pro.f3', true),
    ('pro.f4', false),
    ('pro.f5', false),
  ];

  @override
  Widget build(BuildContext context) {
    final pro = store.pro;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.palette;
        final isPro = store.isPro;
        return Scaffold(
          backgroundColor: p.bg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleBar(palette: p, now: store.now()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: 'C:\\todo> ', style: termStyle(p.dim)),
                      TextSpan(text: 'upgrade', style: termStyle(p.cmd)),
                    ])),
                    const SizedBox(height: 14),
                    Text('todo.exe PRO', style: termStyle(p.hi, size: 22, weight: FontWeight.w700)),
                    Text(tr('pro.sub'), style: termStyle(p.dim, size: 13)),
                    const SizedBox(height: 16),
                    const _ThemePreview(),
                    const SizedBox(height: 16),
                    DashedDivider(color: p.line),
                    const SizedBox(height: 8),
                    for (final f in _features)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isPro ? '[x]' : '[+]', style: termStyle(p.ok)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.$1, style: termStyle(p.hi)),
                                  Text(f.$2, style: termStyle(p.dim, size: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    DashedDivider(color: p.line),
                    const SizedBox(height: 14),
                    if (isPro) ..._activeInfo(p) else ..._buyInfo(p, pro),
                    if (pro?.message != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          '> ${pro!.message}',
                          style: termStyle(pro.messageIsError ? p.warn : p.ok, size: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isPro) ...[
                        Opacity(
                          opacity: (pro?.busy ?? false) ? 0.5 : 1,
                          child: TermWideButton(
                            palette: p,
                            keyLabel: '[ ENTER ]',
                            label: pro?.price == null ? tr('btn.buy') : tr('btn.buy.price', {'price': pro!.price}),
                            onTap: () => pro?.buy(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TermBoxButton(
                                palette: p,
                                label: tr('btn.restore'),
                                textColor: p.cmd,
                                onTap: () => pro?.restore(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TermBoxButton(
                                palette: p,
                                label: '[ ESC ] ${tr('btn.close')}',
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        TermWideButton(
                          palette: p,
                          keyLabel: '[ ESC ]',
                          label: tr('btn.back'),
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _activeInfo(TermPalette p) => [
        Text(tr('pro.active'), style: termStyle(p.ok, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        _tip(p, 'theme amber', tr('pro.tip1')),
        _tip(p, 'crt on', tr('pro.tip2')),
        const SizedBox(height: 6),
        if (_hasWidgets) Text(tr('pro.widget'), style: termStyle(p.dim, size: 13)),
      ];

  List<Widget> _buyInfo(TermPalette p, ProController? pro) {
    final String status;
    if (pro == null || !pro.available) {
      status = tr('pro.nostore');
    } else if (pro.price == null) {
      status = tr('pro.loading');
    } else {
      status = tr('pro.price', {'price': pro.price});
    }
    return [
      Text(status, style: termStyle(p.fg, size: 13)),
      Text(tr('pro.restorehint'), style: termStyle(p.dim, size: 13)),
    ];
  }

  Widget _tip(TermPalette p, String cmd, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(cmd, style: termStyle(p.cmd, size: 13))),
            Expanded(child: Text(desc, style: termStyle(p.dim, size: 13))),
          ],
        ),
      );
}

/// 세 테마를 나란히 보여주는 미리보기.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (i, id) in const ['cmd', 'phosphor', 'amber'].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _swatch(TermPalette.of(id))),
          ],
        ],
      ),
    );
  }

  Widget _swatch(TermPalette t) => Container(
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: t.bg, border: Border.all(color: t.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.id, maxLines: 1, overflow: TextOverflow.clip, style: termStyle(t.hi, size: 11)),
            const Spacer(),
            Text('[x] ok', maxLines: 1, overflow: TextOverflow.clip, style: termStyle(t.ok, size: 11)),
            Text('C:\\>_', maxLines: 1, overflow: TextOverflow.clip, style: termStyle(t.fg, size: 11)),
          ],
        ),
      );
}
