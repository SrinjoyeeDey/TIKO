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

/// Main Child Profile model mirroring backend API response.
class ChildProfile {
  final String id;
  final String? parentId;
  final String name;
  final String ageGroup;
  final String language;
  final int xp;
  final int level;
  final int streak;
  final ChildSkills skills;
  final Map<String, dynamic> preferences;

  const ChildProfile({
    required this.id,
    this.parentId,
    required this.name,
    this.ageGroup = '4-6',
    this.language = 'en',
    this.xp = 0,
    this.level = 1,
    this.streak = 1,
    this.skills = const ChildSkills(),
    this.preferences = const {},
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: (json['id'] ?? json['childId']) as String? ?? 'child_default',
      parentId: (json['parentId'] ?? json['parent_id']) as String?,
      name: json['name'] as String? ?? 'Child',
      ageGroup: json['ageGroup'] as String? ?? '4-6',
      language: json['language'] as String? ?? 'en',
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      streak: json['streak'] as int? ?? 1,
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
      'ageGroup': ageGroup,
      'language': language,
      'xp': xp,
      'level': level,
      'streak': streak,
      'skills': skills.toJson(),
      'preferences': preferences,
    };
  }

  ChildProfile copyWith({
    String? id,
    String? name,
    String? ageGroup,
    String? language,
    int? xp,
    int? level,
    int? streak,
    ChildSkills? skills,
    Map<String, dynamic>? preferences,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      ageGroup: ageGroup ?? this.ageGroup,
      language: language ?? this.language,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      skills: skills ?? this.skills,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'ChildProfile(id: $id, name: $name, xp: $xp, level: $level, streak: $streak)';
  }
}
