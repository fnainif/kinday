import 'dart:convert';

class UserModelSql {
  final int? id;
  final String username;
  final String email;
  final String password;

  UserModelSql({
    this.id,
    required this.username,
    required this.email,
    required this.password,
  });

  // Mengubah data object ke Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'password': password,
    };
  }

  // Mengubah Map dari database menjadi Object Dart
  factory UserModelSql.fromMap(Map<String, dynamic> map) {
    return UserModelSql(
      id: map['id'] != null ? map['id'] as int : null,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelSql.fromJson(String source) =>
      UserModelSql.fromMap(json.decode(source) as Map<String, dynamic>);
}
