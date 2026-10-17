import '../l10n/l10n.dart';
import '../models/task.dart';

/// 명령어 해석과 실행. UI와 저장소에 의존하지 않는 순수 로직이라 테스트하기 쉽다.

enum LogKind { cmd, ok, err, info }

class LogLine {
  const LogLine(this.kind, this.text);

  final LogKind kind;
  final String text;
}

enum FilterKind { all, todo, done, tag }

class TaskFilter {
  const TaskFilter(this.kind, [this.tag = '']);

  static const all = TaskFilter(FilterKind.all);
  static const todo = TaskFilter(FilterKind.todo);
  static const done = TaskFilter(FilterKind.done);

  final FilterKind kind;
  final String tag;

  bool matches(Task t) => switch (kind) {
        FilterKind.all => true,
        FilterKind.todo => !t.done,
        FilterKind.done => t.done,
        FilterKind.tag => t.tag == tag,
      };

  /// 화면 상단 `ls ...` 에 붙는 인자.
  String get flag => switch (kind) {
        FilterKind.all => '',
        FilterKind.todo => '--todo',
        FilterKind.done => '--done',
        FilterKind.tag => '#$tag',
      };

  @override
  bool operator ==(Object other) => other is TaskFilter && other.kind == kind && other.tag == tag;

  @override
  int get hashCode => Object.hash(kind, tag);
}

const themeIds = ['cmd', 'phosphor', 'amber'];

/// 밝기 모드. auto = 폰 설정을 따른다. (cmd 테마에만 적용, 무료)
const modeIds = ['auto', 'light', 'dark'];

class TodoData {
  const TodoData({
    required this.tasks,
    required this.completions,
    required this.nextId,
    this.filter = TaskFilter.all,
    this.theme = 'cmd',
    this.crt = false,
    this.mode = 'auto',
    this.lang = 'auto',
  });

  final List<Task> tasks;
  final List<Completion> completions;
  final int nextId;
  final TaskFilter filter;
  final String theme;
  final bool crt;
  final String mode;

  /// 'auto'(폰 언어를 따름) 또는 언어 코드 (ko · en · ja · zh · fr)
  final String lang;

  int get doneCount => tasks.where((t) => t.done).length;

  TodoData copyWith({
    List<Task>? tasks,
    List<Completion>? completions,
    int? nextId,
    TaskFilter? filter,
    String? theme,
    bool? crt,
    String? mode,
    String? lang,
  }) =>
      TodoData(
        tasks: tasks ?? this.tasks,
        completions: completions ?? this.completions,
        nextId: nextId ?? this.nextId,
        filter: filter ?? this.filter,
        theme: theme ?? this.theme,
        crt: crt ?? this.crt,
        mode: mode ?? this.mode,
        lang: lang ?? this.lang,
      );

  /// 처음 실행했을 때 보여줄 튜토리얼 목록.
  factory TodoData.initial(DateTime now) {
    final seed = [
      (tr('tut.1'), '', 0),
      (tr('tut.2'), '', 1),
      (tr('tut.3'), '', 0),
      (tr('tut.4'), '', 0),
    ];
    return TodoData(
      tasks: [
        for (var i = 0; i < seed.length; i++)
          Task(id: i + 1, text: seed[i].$1, tag: 'tutorial', priority: seed[i].$3, createdAt: now),
      ],
      completions: const [],
      nextId: seed.length + 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'tasks': [for (final t in tasks) t.toJson()],
        'completions': [for (final c in completions) c.toJson()],
        'nextId': nextId,
        'theme': theme,
        'crt': crt,
        'mode': mode,
        'lang': lang,
      };

  factory TodoData.fromJson(Map<String, dynamic> json) {
    final theme = (json['theme'] as String?) ?? 'cmd';
    final mode = (json['mode'] as String?) ?? 'auto';
    return TodoData(
      tasks: [
        for (final t in (json['tasks'] as List? ?? const [])) Task.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
      completions: [
        for (final c in (json['completions'] as List? ?? const []))
          Completion.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      nextId: (json['nextId'] as int?) ?? 1,
      theme: themeIds.contains(theme) ? theme : 'cmd',
      crt: (json['crt'] as bool?) ?? false,
      mode: modeIds.contains(mode) ? mode : 'auto',
      lang: L10n.cleanPref(json['lang'] as String?),
    );
  }
}

class ParsedTask {
  const ParsedTask(this.text, this.tag, this.priority);

  final String text;
  final String tag;
  final int priority;
}

final _tagRe = RegExp(r'#(\S+)');
final _priRe = RegExp(r'(^|\s)(!{1,3})(?=\s|$)');
final _spaceRe = RegExp(r'\s+');

/// `보고서 초안 #work !!` → text: 보고서 초안, tag: work, priority: 2
ParsedTask parseTaskInput(String input) {
  final tag = _tagRe.firstMatch(input)?.group(1) ?? '';
  final priority = _priRe.firstMatch(input)?.group(2)?.length ?? 0;
  var text = input.replaceAll(_tagRe, ' ').replaceAll(_priRe, ' ').replaceAll(_spaceRe, ' ').trim();
  if (text.isEmpty) text = input.trim();
  return ParsedTask(text, tag, priority);
}

String taskNum(int id) => '#${id.toString().padLeft(2, '0')}';

int? _parseId(String arg) {
  final a = arg.trim();
  return int.tryParse(a.startsWith('#') ? a.substring(1) : a);
}

class CommandOutcome {
  const CommandOutcome(this.data, this.lines, {this.clearLog = false, this.route});

  final TodoData data;
  final List<LogLine> lines;

  /// `cls` 일 때 true.
  final bool clearLog;

  /// 열어야 할 화면 ('stats' | 'help' | 'pro' | 'restore' | 'lang').
  final String? route;
}

const knownCommands = {
  'add', 'done', 'undo', 'edit', 'rm', 'ls', 'clear', 'help', 'stats', 'theme', 'crt', //
  'upgrade', 'pro', 'restore', 'mode', 'lang',
};

/// 무료로 쓸 수 있는 테마.
const freeTheme = 'cmd';

/// [pro] 가 false 면 cmd 외 테마와 crt 는 잠겨 있다.
CommandOutcome runCommand(TodoData d, String raw, DateTime now, {bool pro = false}) {
  final s = raw.trim();
  if (s.isEmpty) return CommandOutcome(d, const []);

  final first = s.split(_spaceRe).first;
  var cmd = first.toLowerCase();
  var arg = s.substring(first.length).trim();

  if (cmd == 'cls') return CommandOutcome(d, const [], clearLog: true);

  // 모르는 명령어는 통째로 할 일로 추가한다.
  if (!knownCommands.contains(cmd)) {
    cmd = 'add';
    arg = s;
  }

  final lines = <LogLine>[LogLine(LogKind.cmd, 'C:\\todo> $s')];
  void ok(String t) => lines.add(LogLine(LogKind.ok, t));
  void err(String t) => lines.add(LogLine(LogKind.err, t));
  void info(String t) => lines.add(LogLine(LogKind.info, t));

  var data = d;
  String? route;

  void denied(String what) {
    err('Access is denied.');
    info(tr('denied.info', {'what': what}));
  }

  int findIndex(String a) {
    final id = _parseId(a);
    return id == null ? -1 : d.tasks.indexWhere((t) => t.id == id);
  }

  void notFound(String usage, String a) {
    err(a.isEmpty ? tr('err.usage', {'u': usage}) : tr('err.nf', {'a': a}));
  }

  switch (cmd) {
    case 'add':
      if (arg.isEmpty) {
        err(tr('err.usage', {'u': tr('u.add')}));
        break;
      }
      final p = parseTaskInput(arg);
      final t = Task(id: d.nextId, text: p.text, tag: p.tag, priority: p.priority, createdAt: now);
      data = d.copyWith(tasks: [...d.tasks, t], nextId: d.nextId + 1);
      ok(tr('ok.add', {'n': taskNum(t.id)}));

    case 'done' || 'undo':
      final idx = findIndex(arg);
      if (idx < 0) {
        notFound(tr('u.num', {'cmd': cmd}), arg);
        break;
      }
      final t = d.tasks[idx];
      final makeDone = cmd == 'done';
      if (t.done == makeDone) {
        info(tr('st.already', {'n': taskNum(t.id), 'state': tr(makeDone ? 'state.done' : 'state.todo')}));
        break;
      }
      final tasks = [...d.tasks]..[idx] = t.withDone(makeDone, now);
      var comps = d.completions;
      if (makeDone) {
        comps = [...comps, Completion(taskId: t.id, tag: t.tag, at: now)];
      } else {
        final ci = comps.lastIndexWhere((c) => c.taskId == t.id);
        if (ci >= 0) comps = [...comps]..removeAt(ci);
      }
      data = d.copyWith(tasks: tasks, completions: comps);
      ok(tr(makeDone ? 'ok.done' : 'ok.undo', {'n': taskNum(t.id)}));

    case 'edit':
      final idPart = arg.split(_spaceRe).first;
      final rest = arg.substring(idPart.length).trim();
      final idx = findIndex(idPart);
      if (idx < 0 || rest.isEmpty) {
        if (idx < 0 && idPart.isNotEmpty) {
          notFound(tr('u.edit'), idPart);
        } else {
          err(tr('err.usage', {'u': tr('u.edit')}));
        }
        break;
      }
      final t = d.tasks[idx];
      final p = parseTaskInput(rest);
      final updated = t.withContent(
        text: p.text,
        tag: _tagRe.hasMatch(rest) ? p.tag : t.tag,
        priority: _priRe.hasMatch(rest) ? p.priority : t.priority,
      );
      data = d.copyWith(tasks: [...d.tasks]..[idx] = updated);
      ok(tr('ok.edit', {'n': taskNum(t.id)}));

    case 'rm':
      final idx = findIndex(arg);
      if (idx < 0) {
        notFound(tr('u.num', {'cmd': 'rm'}), arg);
        break;
      }
      final t = d.tasks[idx];
      data = d.copyWith(tasks: [...d.tasks]..removeAt(idx));
      ok(tr('ok.rm', {'n': taskNum(t.id)}));

    case 'ls':
      TaskFilter? f;
      if (arg.isEmpty || arg == '--all' || arg == '-a') {
        f = TaskFilter.all;
      } else if (arg == '--todo') {
        f = TaskFilter.todo;
      } else if (arg == '--done') {
        f = TaskFilter.done;
      } else if (arg.startsWith('#') && arg.length > 1) {
        f = TaskFilter(FilterKind.tag, arg.substring(1));
      }
      if (f == null) {
        err(tr('ls.bad', {'a': arg}));
        break;
      }
      data = d.copyWith(filter: f);
      info(tr('ls.count', {'n': d.tasks.where(f.matches).length}));

    case 'clear':
      final n = d.doneCount;
      if (n == 0) {
        info(tr('clear.none'));
        break;
      }
      data = d.copyWith(tasks: d.tasks.where((t) => !t.done).toList());
      ok(tr('clear.ok', {'n': n}));

    case 'help':
      info(tr('help.1'));
      info(tr('help.2'));
      info(tr('help.3'));

    case 'stats':
      route = 'stats';

    case 'upgrade' || 'pro':
      route = 'pro';

    case 'restore':
      route = 'restore';

    case 'mode':
      final a = arg.toLowerCase();
      if (a.isEmpty) {
        info(tr('mode.cur', {'m': d.mode, 'list': modeIds.join(' | ')}));
      } else if (!modeIds.contains(a)) {
        err(tr('mode.bad', {'a': arg, 'list': modeIds.join(' | ')}));
      } else {
        data = d.copyWith(mode: a);
        ok(tr('mode.set', {'m': a}));
        if (pro && d.theme != freeTheme) info(tr('mode.note'));
      }

    case 'theme':
      final a = arg.toLowerCase();
      if (a.isEmpty) {
        info(tr('theme.cur', {'t': pro ? d.theme : freeTheme, 'list': themeIds.join(' | ')}));
        if (!pro) info(tr('theme.pro'));
      } else if (!themeIds.contains(a)) {
        err(tr('theme.bad', {'a': arg, 'list': themeIds.join(' | ')}));
      } else if (a != freeTheme && !pro) {
        denied(tr('denied.theme', {'a': a}));
      } else {
        data = d.copyWith(theme: a);
        ok(tr('theme.set', {'t': a}));
      }

    case 'crt':
      if (!pro) {
        denied(tr('denied.crt'));
        break;
      }
      final a = arg.toLowerCase();
      final bool? next = switch (a) {
        '' => !d.crt,
        'on' => true,
        'off' => false,
        _ => null,
      };
      if (next == null) {
        err(tr('err.usage', {'u': tr('u.crt')}));
        break;
      }
      data = d.copyWith(crt: next);
      ok('crt ${next ? 'on' : 'off'}');

    case 'lang':
      final a = arg.toLowerCase();
      String show(String pref) =>
          pref == L10n.autoPref ? 'auto (${L10n.current.label})' : (L10n.langFromCode(pref)?.label ?? pref);
      if (a.isEmpty) {
        info(tr('lang.cur', {'l': show(L10n.pref), 'list': L10n.prefs.join(' | ')}));
        route = 'lang';
      } else if (!L10n.isPref(a)) {
        err(tr('lang.bad', {'a': arg, 'list': L10n.prefs.join(' | ')}));
      } else {
        // 앞으로 나오는 문구(이 줄 포함)가 새 언어로 나온다.
        L10n.pref = a;
        data = d.copyWith(lang: a);
        ok(tr('lang.set', {'l': show(a)}));
      }
  }

  return CommandOutcome(data, lines, route: route);
}
