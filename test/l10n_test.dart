import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_exe/l10n/l10n.dart';
import 'package:todo_exe/widget_sync.dart';

Set<String> _placeholders(String s) => {for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m.group(1)!};

void main() {
  final tables = l10nTables;

  test('모든 언어에 같은 키가 있다', () {
    final base = tables[Lang.ko]!.keys.toSet();
    for (final l in Lang.values) {
      final keys = tables[l]!.keys.toSet();
      expect(base.difference(keys), isEmpty, reason: '${l.code} 에 없는 키');
      expect(keys.difference(base), isEmpty, reason: '${l.code} 에만 있는 키');
    }
  });

  test('비어 있는 문구가 없고, {자리} 가 모든 언어에서 같다', () {
    for (final key in tables[Lang.ko]!.keys) {
      final ko = tables[Lang.ko]![key]!;
      for (final l in Lang.values) {
        final s = tables[l]![key]!;
        // 아래 키는 일부 언어에서 일부러 한 칸이거나 비어 있을 수 있어서 길이만 본다.
        expect(s.isNotEmpty, isTrue, reason: '${l.code}/$key 가 비었어요');
        expect(_placeholders(s), _placeholders(ko), reason: '${l.code}/$key 의 {자리} 가 달라요');
      }
    }
  });

  test('도움말에 나오는 명령어마다 설명이 있다', () {
    for (final cmd in ['add', 'done', 'undo', 'edit', 'rm', 'ls', 'clear', 'cls', 'stats', 'theme', 'mode', 'lang', 'crt', 'upgrade', 'restore']) {
      expect(trHas('h.$cmd.d'), isTrue, reason: 'h.$cmd.d');
    }
  });

  test('위젯으로 보내는 키가 모두 있다', () {
    for (final k in widgetStringKeys) {
      expect(trHas(k), isTrue, reason: k);
    }
  });

  test('요일은 월요일부터 7개', () {
    for (final l in Lang.values) {
      final names = [for (var i = 1; i <= 7; i++) trIn(l, 'wd.$i')];
      expect(names.toSet().length, 7, reason: l.code);
    }
  });

  test('값을 채우고, 없는 키는 키 이름을 돌려준다', () {
    expect(trIn(Lang.en, 'ok.add', {'n': '#03'}), '+ #03 added');
    expect(trIn(Lang.ko, 'ok.add', {'n': '#03'}), '+ #03 추가됨');
    expect(trIn(Lang.fr, 'nope.nope'), 'nope.nope');
  });

  test('폰 언어 → 앱 언어: 지원 안 하는 언어는 영어, auto 는 폰을 따른다', () {
    expect(L10n.fromLocale(const Locale('ko', 'KR')), Lang.ko);
    expect(L10n.fromLocale(const Locale('fr', 'FR')), Lang.fr);
    expect(L10n.fromLocale(const Locale('ja', 'JP')), Lang.ja);
    expect(L10n.fromLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW')), Lang.zh);
    expect(L10n.fromLocale(const Locale('de', 'DE')), Lang.en);

    L10n.syncDevice(const Locale('fr'));
    L10n.pref = 'auto';
    expect(L10n.current, Lang.fr);
    L10n.pref = 'ja';
    expect(L10n.current, Lang.ja);
    L10n.pref = 'garbage';
    expect(L10n.current, Lang.fr); // 모르는 값이면 폰 언어
    expect(L10n.cleanPref('garbage'), 'auto');
    expect(L10n.cleanPref(null), 'auto');
    expect(L10n.cleanPref('zh'), 'zh');
    L10n.pref = 'auto';
  });
}
