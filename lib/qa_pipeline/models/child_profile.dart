/// Represents a child learner's profile stored locally.
class ChildProfile {
  final String id;
  final String name;
  final int? age;
  final String? className;
  final DateTime createdAt;

  const ChildProfile({
    required this.id,
    required this.name,
    this.age,
    this.className,
    required this.createdAt,
  });

  /// Creates a [ChildProfile] from a database row map.
  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int?,
      className: map['class_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'class_name': className,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'ChildProfile(id: $id, name: $name, age: $age, class: $className)';
}
