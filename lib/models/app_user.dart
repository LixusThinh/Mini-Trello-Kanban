class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser(id: json['id'] as String, email: json['email'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'email': email};

  AppUser copyWith({String? id, String? email}) =>
      AppUser(id: id ?? this.id, email: email ?? this.email);
}
