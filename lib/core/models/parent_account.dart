import 'dart:math';

/// Represents a persistent Parent Account in NIMO.
class ParentAccount {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String? pinHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.pinHash,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.toLowerCase().trim(),
      'password_hash': passwordHash,
      'pin_hash': pinHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ParentAccount.fromMap(Map<String, dynamic> map) {
    return ParentAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: (map['password_hash'] ?? map['passwordHash']) as String? ?? '',
      pinHash: (map['pin_hash'] ?? map['pinHash']) as String?,
      createdAt: DateTime.parse((map['created_at'] ?? map['createdAt']) as String),
      updatedAt: DateTime.parse((map['updated_at'] ?? map['updatedAt']) as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'parentId': id,
    'name': name,
    'email': email,
    'role': 'parent',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ParentAccount.fromJson(Map<String, dynamic> json) => ParentAccount(
    id: json['parentId'] ?? json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    passwordHash: json['passwordHash'] ?? '',
    pinHash: json['pinHash'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
  );

  ParentAccount copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? pinHash,
    DateTime? updatedAt,
  }) {
    return ParentAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      pinHash: pinHash ?? this.pinHash,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
