import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model_sql.dart';

class UserModelFirebase {
  final String? uid;
  final String username;
  final String email;
  final String password;

  UserModelFirebase({
    this.uid,
    required this.username,
    required this.email,
    this.password = '',
  });

  // Mengubah data object ke Map (untuk disimpan ke Firestore/Database)
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'username': username,
      'email': email,
    };
  }

  // Mengubah Map dari database menjadi Object Dart
  factory UserModelFirebase.fromMap(Map<String, dynamic> map) {
    return UserModelFirebase(
      uid: map['uid'] as String?,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
    );
  }

  // Membuat Object Dart dari DocumentSnapshot Firestore
  factory UserModelFirebase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModelFirebase(
      uid: doc.id, // Menggunakan Document ID sebagai UID
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
    );
  }

  // Mengubah data object ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
    };
  }

  // Helper untuk mengubah data dari UserModelSql ke UserModelFirebase
  factory UserModelFirebase.fromSql(UserModelSql sqlModel) {
    return UserModelFirebase(
      uid: sqlModel.id?.toString(),
      username: sqlModel.username,
      email: sqlModel.email,
      password: sqlModel.password,
    );
  }

  // Helper untuk mengubah UserModelFirebase menjadi UserModelSql
  UserModelSql toSql() {
    return UserModelSql(
      id: uid != null ? int.tryParse(uid!) : null,
      username: username,
      email: email,
      password: password,
    );
  }

  UserModelFirebase copyWith({
    String? uid,
    String? username,
    String? email,
    String? password,
  }) {
    return UserModelFirebase(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelFirebase.fromJson(String source) =>
      UserModelFirebase.fromMap(json.decode(source) as Map<String, dynamic>);
}
