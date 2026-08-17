/// Represents a child learner's profile stored locally in SQLite.
class ChildProfile {
  final String id;
  final String? parentId;
  final String name;
  final int? age;
  final String? className;
  final int difficultyPercentage;
  final String? difficultyLevel;
  final String? difficultyReasoning;
  final DateTime createdAt;

  const ChildProfile({
    required this.id,
    this.parentId,
    required this.name,
    this.age,
    this.className,
    this.difficultyPercentage = 50,
    this.difficultyLevel,
    this.difficultyReasoning,
    required this.createdAt,
  });

  /// Getter for standard/grade alias
  String get standard => className ?? 'Grade 1';

  /// Creates a [ChildProfile] from a database row map.
  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      parentId: map['parent_id'] as String?,
      name: map['name'] as String,
      age: map['age'] as int?,
      className: map['class_name'] as String?,
      difficultyPercentage: (map['difficulty_percentage'] as num?)?.toInt() ?? 50,
      difficultyLevel: map['difficulty_level'] as String?,
      difficultyReasoning: map['difficulty_reasoning'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
    );
  }

  /// Converts to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'age': age,
      'class_name': className,
      'difficulty_percentage': difficultyPercentage,
      'difficulty_level': difficultyLevel,
      'difficulty_reasoning': difficultyReasoning,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChildProfile copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    String? className,
    int? difficultyPercentage,
    String? difficultyLevel,
    String? difficultyReasoning,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      className: className ?? this.className,
      difficultyPercentage: difficultyPercentage ?? this.difficultyPercentage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      difficultyReasoning: difficultyReasoning ?? this.difficultyReasoning,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ChildProfile(id: $id, name: $name, age: $age, class: $className, difficulty: $difficultyPercentage%)';
}
