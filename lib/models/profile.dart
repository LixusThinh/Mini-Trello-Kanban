class Profile {
  final String id;
  final String fullName;
  final String? avatarUrl;

  const Profile({required this.id, required this.fullName, this.avatarUrl});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: (json['full_name'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'avatar_url': avatarUrl,
  };

  Profile copyWith({String? id, String? fullName, String? avatarUrl}) =>
      Profile(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
