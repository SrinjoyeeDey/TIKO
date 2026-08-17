/// Represents individual skill domain ratings (0-100)
class ChildSkills {
  final int speech;
  final int memory;
  final int sequencing;
  final int motor;
  final int recognition;
  final int attention;

  const ChildSkills({
    this.speech = 0,
    this.memory = 0,
    this.sequencing = 0,
    this.motor = 0,
    this.recognition = 0,
    this.attention = 0,
  });

  factory ChildSkills.fromJson(Map<String, dynamic> json) {
    return ChildSkills(
      speech: json['speech'] as int? ?? 0,
      memory: json['memory'] as int? ?? 0,
      sequencing: json['sequencing'] as int? ?? 0,
      motor: json['motor'] as int? ?? 0,
      recognition: json['recognition'] as int? ?? 0,
      attention: json['attention'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speech': speech,
      'memory': memory,
      'sequencing': sequencing,
      'motor': motor,
      'recognition': recognition,
      'attention': attention,
    };
  }

  ChildSkills copyWith({
    int? speech,
    int? memory,
    int? sequencing,
    int? motor,
    int? recognition,
    int? attention,
  }) {
    return ChildSkills(
      speech: speech ?? this.speech,
      memory: memory ?? this.memory,
      sequencing: sequencing ?? this.sequencing,
      motor: motor ?? this.motor,
      recognition: recognition ?? this.recognition,
      attention: attention ?? this.attention,
    );
  }
}

/// Main Child Profile model mirroring backend API & local SQLite profile state.
class ChildProfile {
  final String id;
  final String? parentId;
  final String name;
  final int? age;
  final String? className;
  final String ageGroup;
  final String language;
  final int xp;
  final int level;
  final int streak;
  final int difficultyPercentage;
  final String? difficultyLevel;
  final String? difficultyReasoning;
  final ChildSkills skills;
  final Map<String, dynamic> preferences;

  const ChildProfile({
    required this.id,
    this.parentId,
    required this.name,
    this.age,
    this.className,
    this.ageGroup = '4-6',
    this.language = 'en',
    this.xp = 0,
    this.level = 1,
    this.streak = 1,
    this.difficultyPercentage = 50,
    this.difficultyLevel,
    this.difficultyReasoning,
    this.skills = const ChildSkills(),
    this.preferences = const {},
  });

  String get standard => className ?? 'Grade 1';

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: (json['id'] ?? json['childId']) as String? ?? 'child_default',
      parentId: (json['parentId'] ?? json['parent_id']) as String?,
      name: json['name'] as String? ?? 'Child',
      age: json['age'] as int?,
      className: (json['className'] ?? json['class_name'] ?? json['standard']) as String?,
      ageGroup: json['ageGroup'] as String? ?? (json['age'] != null ? '${json['age']} yrs' : '4-6'),
      language: json['language'] as String? ?? 'en',
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      streak: json['streak'] as int? ?? 1,
      difficultyPercentage: (json['difficultyPercentage'] ?? json['difficulty_percentage'] as num?)?.toInt() ?? 50,
      difficultyLevel: (json['difficultyLevel'] ?? json['difficulty_level']) as String?,
      difficultyReasoning: (json['difficultyReasoning'] ?? json['difficulty_reasoning']) as String?,
      skills: json['skills'] != null
          ? ChildSkills.fromJson(Map<String, dynamic>.from(json['skills'] as Map))
          : const ChildSkills(),
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'className': className,
      'standard': standard,
      'ageGroup': ageGroup,
      'language': language,
      'xp': xp,
      'level': level,
      'streak': streak,
      'difficultyPercentage': difficultyPercentage,
      'difficultyLevel': difficultyLevel,
      'difficultyReasoning': difficultyReasoning,
      'skills': skills.toJson(),
      'preferences': preferences,
    };
  }

  ChildProfile copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    String? className,
    String? ageGroup,
    String? language,
    int? xp,
    int? level,
    int? streak,
    int? difficultyPercentage,
    String? difficultyLevel,
    String? difficultyReasoning,
    ChildSkills? skills,
    Map<String, dynamic>? preferences,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      className: className ?? this.className,
      ageGroup: ageGroup ?? this.ageGroup,
      language: language ?? this.language,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      difficultyPercentage: difficultyPercentage ?? this.difficultyPercentage,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      difficultyReasoning: difficultyReasoning ?? this.difficultyReasoning,
      skills: skills ?? this.skills,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'ChildProfile(id: $id, name: $name, age: $age, standard: $standard, diff: $difficultyPercentage%)';
  }
}
