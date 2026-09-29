/// 할 일 한 줄.
class Task {
  const Task({
    required this.id,
    required this.text,
    this.tag = '',
    this.priority = 0,
    this.done = false,
    required this.createdAt,
    this.doneAt,
  });

  final int id;
  final String text;

  /// `#` 없이 저장. 비어 있으면 태그 없음.
  final String tag;

  /// 0~3 (`!` 개수).
  final int priority;
  final bool done;
  final DateTime createdAt;
  final DateTime? doneAt;

  Task withDone(bool value, DateTime now) => Task(
        id: id,
        text: text,
        tag: tag,
        priority: priority,
        done: value,
        createdAt: createdAt,
        doneAt: value ? now : null,
      );

  Task withContent({required String text, required String tag, required int priority}) => Task(
        id: id,
        text: text,
        tag: tag,
        priority: priority,
        done: done,
        createdAt: createdAt,
        doneAt: doneAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'tag': tag,
        'priority': priority,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        if (doneAt != null) 'doneAt': doneAt!.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        text: json['text'] as String,
        tag: (json['tag'] as String?) ?? '',
        priority: (json['priority'] as int?) ?? 0,
        done: (json['done'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        doneAt: json['doneAt'] == null ? null : DateTime.parse(json['doneAt'] as String),
      );
}

/// 완료 기록. 할 일을 지우거나 clear 해도 통계용으로 남는다.
class Completion {
  const Completion({required this.taskId, required this.tag, required this.at});

  final int taskId;
  final String tag;
  final DateTime at;

  Map<String, dynamic> toJson() => {'taskId': taskId, 'tag': tag, 'at': at.toIso8601String()};

  factory Completion.fromJson(Map<String, dynamic> json) => Completion(
        taskId: json['taskId'] as int,
        tag: (json['tag'] as String?) ?? '',
        at: DateTime.parse(json['at'] as String),
      );
}
