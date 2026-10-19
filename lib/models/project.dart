class Project {
  final String id;
  final String title;
  final String? description;
  final String ownerId;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.title,
    this.description,
    required this.ownerId,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    ownerId: json['owner_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'owner_id': ownerId,
    'created_at': createdAt.toIso8601String(),
  };

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? ownerId,
    DateTime? createdAt,
  }) => Project(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    ownerId: ownerId ?? this.ownerId,
    createdAt: createdAt ?? this.createdAt,
  );
}
