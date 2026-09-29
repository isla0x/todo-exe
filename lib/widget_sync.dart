import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

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

  static Future<void> push(TodoData d, DateTime now) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(snapshotKey, jsonEncode(widgetSnapshot(d, now)));
      await HomeWidget.updateWidget(iOSName: iOSWidgetKind);
    } catch (e) {
      // 위젯 타깃이 아직 없거나 App Group 이 꺼져 있어도 앱은 계속 동작해야 한다.
      debugPrint('todo.exe widget: 업데이트 실패 ($e)');
    }
  }
}

/// 위젯이 읽는 JSON. Swift 쪽 `TodoSnapshot` 과 키가 같아야 한다.
Map<String, dynamic> widgetSnapshot(TodoData d, DateTime now, {int maxItems = 8}) {
  final todo = d.tasks.where((t) => !t.done).toList()
    ..sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
  return {
    'v': 1,
    'theme': d.theme,
    'done': d.doneCount,
    'total': d.tasks.length,
    'streak': Stats.compute(d, now).streak,
    'todo': [
      for (final t in todo.take(maxItems)) {'n': taskNum(t.id), 't': t.text, 'p': t.priority, 'g': t.tag},
    ],
  };
}
