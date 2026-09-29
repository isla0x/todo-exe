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
  });

  final List<Task> tasks;
  final List<Completion> completions;
  final int nextId;
  final TaskFilter filter;
  final String theme;
  final bool crt;
  final String mode;

  int get doneCount => tasks.where((t) => t.done).length;

  TodoData copyWith({
    List<Task>? tasks,
    List<Completion>? completions,
    int? nextId,
    TaskFilter? filter,
    String? theme,
    bool? crt,
    String? mode,
  }) =>
      TodoData(
        tasks: tasks ?? this.tasks,
        completions: completions ?? this.completions,
        nextId: nextId ?? this.nextId,
        filter: filter ?? this.filter,
        theme: theme ?? this.theme,
        crt: crt ?? this.crt,
        mode: mode ?? this.mode,
      );

  /// 처음 실행했을 때 보여줄 튜토리얼 목록.
  factory TodoData.initial(DateTime now) {
    final seed = [
      ('이 줄을 탭하면 완료돼요', '', 0),
      ('아래 입력창에 할 일을 쓰고 Enter', '', 1),
      ('help 를 입력해서 명령어 보기', '', 0),
      ('rm 버튼으로 이 줄 지우기', '', 0),
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

  /// 열어야 할 화면 ('stats' | 'help').
  final String? route;
}

const knownCommands = {
  'add', 'done', 'undo', 'edit', 'rm', 'ls', 'clear', 'help', 'stats', 'theme', 'crt', //
  'upgrade', 'pro', 'restore', 'mode',
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
    info("$what 은(는) PRO 기능이에요. 'upgrade' 로 열 수 있어요.");
  }

  int findIndex(String a) {
    final id = _parseId(a);
    return id == null ? -1 : d.tasks.indexWhere((t) => t.id == id);
  }

  void notFound(String usage, String a) {
    err(a.isEmpty ? '사용법: $usage' : "'$a' 번 항목을 찾을 수 없어요.");
  }

  switch (cmd) {
    case 'add':
      if (arg.isEmpty) {
        err('사용법: add <할 일> [#태그] [!]');
        break;
      }
      final p = parseTaskInput(arg);
      final t = Task(id: d.nextId, text: p.text, tag: p.tag, priority: p.priority, createdAt: now);
      data = d.copyWith(tasks: [...d.tasks, t], nextId: d.nextId + 1);
      ok('+ ${taskNum(t.id)} 추가됨');

    case 'done' || 'undo':
      final idx = findIndex(arg);
      if (idx < 0) {
        notFound('$cmd <번호>', arg);
        break;
      }
      final t = d.tasks[idx];
      final makeDone = cmd == 'done';
      if (t.done == makeDone) {
        info('${taskNum(t.id)} 는 이미 ${makeDone ? '완료' : '할 일'} 상태예요.');
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
      ok(makeDone ? '✓ ${taskNum(t.id)} 완료' : '~ ${taskNum(t.id)} 되돌림');

    case 'edit':
      final idPart = arg.split(_spaceRe).first;
      final rest = arg.substring(idPart.length).trim();
      final idx = findIndex(idPart);
      if (idx < 0 || rest.isEmpty) {
        if (idx < 0 && idPart.isNotEmpty) {
          notFound('edit <번호> <내용>', idPart);
        } else {
          err('사용법: edit <번호> <내용>');
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
      ok('* ${taskNum(t.id)} 수정됨');

    case 'rm':
      final idx = findIndex(arg);
      if (idx < 0) {
        notFound('rm <번호>', arg);
        break;
      }
      final t = d.tasks[idx];
      data = d.copyWith(tasks: [...d.tasks]..removeAt(idx));
      ok('- ${taskNum(t.id)} 삭제됨');

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
        err("ls: 알 수 없는 옵션 '$arg'");
        break;
      }
      data = d.copyWith(filter: f);
      info('${d.tasks.where(f.matches).length}개 항목');

    case 'clear':
      final n = d.doneCount;
      if (n == 0) {
        info('정리할 완료 항목이 없어요.');
        break;
      }
      data = d.copyWith(tasks: d.tasks.where((t) => !t.done).toList());
      ok('완료 항목 $n건 정리됨');

    case 'help':
      info('add · done · undo · edit · rm · ls');
      info('clear · cls · stats · theme · mode · crt · upgrade');
      info('자세한 설명은 상단 help');

    case 'stats':
      route = 'stats';

    case 'upgrade' || 'pro':
      route = 'pro';

    case 'restore':
      route = 'restore';

    case 'mode':
      final a = arg.toLowerCase();
      if (a.isEmpty) {
        info('현재 모드: ${d.mode}  (${modeIds.join(' | ')})');
      } else if (!modeIds.contains(a)) {
        err("mode: '$arg' 는 없는 모드예요. (${modeIds.join(' | ')})");
      } else {
        data = d.copyWith(mode: a);
        ok('모드 변경: $a');
        if (pro && d.theme != freeTheme) info('밝은 모드는 cmd 테마에서만 보여요.');
      }

    case 'theme':
      final a = arg.toLowerCase();
      if (a.isEmpty) {
        info('현재 테마: ${pro ? d.theme : freeTheme}  (${themeIds.join(' | ')})');
        if (!pro) info("phosphor · amber 는 PRO 테마예요. 'upgrade'");
      } else if (!themeIds.contains(a)) {
        err("theme: '$arg' 는 없는 테마예요. (${themeIds.join(' | ')})");
      } else if (a != freeTheme && !pro) {
        denied('$a 테마');
      } else {
        data = d.copyWith(theme: a);
        ok('테마 변경: $a');
      }

    case 'crt':
      if (!pro) {
        denied('crt 효과');
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
        err('사용법: crt [on | off]');
        break;
      }
      data = d.copyWith(crt: next);
      ok('crt ${next ? 'on' : 'off'}');
  }

  return CommandOutcome(data, lines, route: route);
}
