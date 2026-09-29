import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/commands.dart';
import '../theme/term_palette.dart';

/// 앱 상태. 명령어를 실행하고 기기에 저장한다.
class TodoStore extends ChangeNotifier {
  TodoStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _data = TodoData.initial(_clock());
  }

  static const _key = 'todo_exe_state_v1';
  static const _maxLog = 4;
  static const _maxHistory = 50;

  final DateTime Function() _clock;
  late TodoData _data;
  SharedPreferences? _prefs;

  final List<LogLine> _log = [
    const LogLine(LogKind.info, "'help' 를 입력하면 명령어 목록을 볼 수 있어요."),
  ];
  final List<String> _history = [];

  TodoData get data => _data;
  List<LogLine> get log => List.unmodifiable(_log);
  List<String> get history => List.unmodifiable(_history);
  TermPalette get palette => TermPalette.of(_data.theme);
  DateTime now() => _clock();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      _data = TodoData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (e) {
      debugPrint('todo.exe: 저장된 데이터를 읽지 못해 새로 시작합니다. ($e)');
    }
  }

  /// 명령어를 실행하고, 열어야 할 화면이 있으면 그 이름을 돌려준다.
  String? run(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    _history.add(s);
    if (_history.length > _maxHistory) _history.removeAt(0);

    final out = runCommand(_data, s, _clock());
    _data = out.data;
    if (out.clearLog) {
      _log.clear();
    } else {
      _log.addAll(out.lines);
      if (_log.length > _maxLog) _log.removeRange(0, _log.length - _maxLog);
    }
    notifyListeners();
    _save();
    return out.route;
  }

  void _save() {
    _prefs?.setString(_key, jsonEncode(_data.toJson()));
  }
}
