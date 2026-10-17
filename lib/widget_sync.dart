import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'l10n/l10n.dart';
import 'logic/commands.dart';
import 'logic/stats.dart';

/// 홈 화면·잠금화면 위젯(iOS WidgetKit)으로 데이터를 넘긴다.
///
/// 앱과 위젯은 App Group 저장소를 같이 쓴다. Xcode 에서 Runner 와 TodoWidget
/// 두 타깃 모두 아래 [appGroupId] 로 App Groups 를 켜야 한다.
class WidgetSync {
  static const appGroupId = 'group.com.isla0x.todoexe';
  static const iOSWidgetKind = 'TodoWidget';
  static const snapshotKey = 'snapshot';

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> init() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('todo.exe widget: setAppGroupId 실패 ($e)');
    }
  }

  static Future<void> push(TodoData d, DateTime now, {required bool pro}) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(snapshotKey, jsonEncode(widgetSnapshot(d, now, pro: pro)));
      await HomeWidget.updateWidget(iOSName: iOSWidgetKind);
    } catch (e) {
      // 위젯 타깃이 아직 없거나 App Group 이 꺼져 있어도 앱은 계속 동작해야 한다.
      debugPrint('todo.exe widget: 업데이트 실패 ($e)');
    }
  }
}

/// 위젯에 보낼 문구. 위젯은 별도 프로세스라서 앱이 지금 언어로 만든 문구를 같이 넘긴다.
/// 값 안의 `{n}` 같은 자리는 Swift 쪽에서 채운다.
const widgetStringKeys = [
  'w.empty',
  'w.done',
  'w.add.post',
  'w.streak',
  'w.none',
  'w.alldone',
  'w.inline',
  'w.locked.1',
  'w.locked.pre',
  'w.locked.post',
  'w.locked.inline',
  'w.locked.rect',
];

/// 위젯이 읽는 JSON. Swift 쪽 `TodoSnapshot` 과 키가 같아야 한다.
///
/// [pro] 가 false 면 위젯은 잠금 화면('Access is denied.')을 그리고, 테마는 cmd 로 고정된다.
Map<String, dynamic> widgetSnapshot(TodoData d, DateTime now, {bool pro = false, int maxItems = 8}) {
  final todo = d.tasks.where((t) => !t.done).toList()
    ..sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
  return {
    'v': 3,
    'pro': pro,
    'theme': pro ? d.theme : freeTheme,
    // 위젯은 auto 일 때 iOS 의 다크/라이트 설정을 직접 따른다.
    'mode': d.mode,
    'done': d.doneCount,
    'total': d.tasks.length,
    'streak': Stats.compute(d, now).streak,
    // 월~일 이름 (월요일부터)
    'wd': weekdayNames(),
    's': {for (final k in widgetStringKeys) k: tr(k)},
    'todo': [
      for (final t in todo.take(maxItems)) {'n': taskNum(t.id), 't': t.text, 'p': t.priority, 'g': t.tag},
    ],
  };
}
