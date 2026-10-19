enum TaskStatus {
  todo('TODO', 'Cần làm (To Do)'),
  inProgress('IN_PROGRESS', 'Đang làm (In Progress)'),
  done('DONE', 'Hoàn thành (Done)');

  const TaskStatus(this.db, this.label);
  final String db;
  final String label;
  static TaskStatus fromDb(String v) => values.firstWhere((s) => s.db == v);
}

class Task {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final String? attachmentUrl;
  final String createdBy;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.attachmentUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    projectId: json['project_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    status: TaskStatus.fromDb(json['status'] as String),
    attachmentUrl: json['attachment_url'] as String?,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'title': title,
    'description': description,
    'status': status.db,
    'attachment_url': attachmentUrl,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    String? attachmentUrl,
    String? createdBy,
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );
}
