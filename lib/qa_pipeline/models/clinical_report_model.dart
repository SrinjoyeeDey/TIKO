/// Post-Play Clinical & Parental Report Model
/// Standardized JSON schema for autistic child play session analytics,
/// detailing sensory engagement, speech progress, cognitive/motor skills,
/// behavioral indicators, and actionable insights for parents and clinicians.
class ClinicalReport {
  final ReportMetadata metadata;
  final SessionSummary sessionSummary;
  final SensoryAndAttention sensoryAndAttention;
  final SpeechAndCommunication speechAndCommunication;
  final CognitiveAndMotorSkills cognitiveAndMotorSkills;
  final BehavioralObservations behavioralObservations;
  final ActionableInsights actionableInsights;
  final int totalEventsAnalyzed;

  ClinicalReport({
    required this.metadata,
    required this.sessionSummary,
    required this.sensoryAndAttention,
    required this.speechAndCommunication,
    required this.cognitiveAndMotorSkills,
    required this.behavioralObservations,
    required this.actionableInsights,
    this.totalEventsAnalyzed = 0,
  });

  bool get hasSufficientData => totalEventsAnalyzed > 0;

  // Convenient legacy getters to preserve compatibility
  double get visualEngagementScore => sensoryAndAttention.visualEngagementScore;
  int get distractionEvents => sensoryAndAttention.distractionEvents;
  int get totalVocalizations => speechAndCommunication.totalVocalizations;
  double get pronunciationAccuracy => speechAndCommunication.pronunciationAccuracy;
  double get averageResponseDelaySeconds => speechAndCommunication.averageResponseDelaySeconds;
  int get frustrationIndicators => behavioralObservations.frustrationIndicators;

  factory ClinicalReport.fromJson(Map<String, dynamic> json) {
    return ClinicalReport(
      metadata: ReportMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? {}),
      sessionSummary: SessionSummary.fromJson(json['sessionSummary'] as Map<String, dynamic>? ?? {}),
      sensoryAndAttention: SensoryAndAttention.fromJson(json['sensoryAndAttention'] as Map<String, dynamic>? ?? {}),
      speechAndCommunication: SpeechAndCommunication.fromJson(json['speechAndCommunication'] as Map<String, dynamic>? ?? {}),
      cognitiveAndMotorSkills: CognitiveAndMotorSkills.fromJson(json['cognitiveAndMotorSkills'] as Map<String, dynamic>? ?? {}),
      behavioralObservations: BehavioralObservations.fromJson(json['behavioralObservations'] as Map<String, dynamic>? ?? {}),
      actionableInsights: ActionableInsights.fromJson(json['actionableInsights'] as Map<String, dynamic>? ?? {}),
      totalEventsAnalyzed: (json['totalEventsAnalyzed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'sessionSummary': sessionSummary.toJson(),
      'sensoryAndAttention': sensoryAndAttention.toJson(),
      'speechAndCommunication': speechAndCommunication.toJson(),
      'cognitiveAndMotorSkills': cognitiveAndMotorSkills.toJson(),
      'behavioralObservations': behavioralObservations.toJson(),
      'actionableInsights': actionableInsights.toJson(),
      'totalEventsAnalyzed': totalEventsAnalyzed,
    };
  }

  static ClinicalReport empty({String childId = 'child_123', String sessionId = 'SES_001'}) {
    return ClinicalReport(
      metadata: ReportMetadata(
        reportId: 'RPT_${DateTime.now().millisecondsSinceEpoch}',
        childId: childId,
        sessionId: sessionId,
        date: DateTime.now().toUtc().toIso8601String(),
      ),
      sessionSummary: SessionSummary(
        durationMinutes: 0.0,
        activitiesCompleted: 0,
        overallEngagement: 'Low',
      ),
      sensoryAndAttention: SensoryAndAttention(
        visualEngagementScore: 0.0,
        distractionEvents: 0,
        sensoryPreferences: [],
      ),
      speechAndCommunication: SpeechAndCommunication(
        totalVocalizations: 0,
        pronunciationAccuracy: 0.0,
        successfulWords: [],
        averageResponseDelaySeconds: 0.0,
      ),
      cognitiveAndMotorSkills: CognitiveAndMotorSkills(
        memory: 0.0,
        sequencing: 0.0,
        fineMotorControl: 0.0,
        areasOfStruggle: [],
      ),
      behavioralObservations: BehavioralObservations(
        hintsRequested: 0,
        abandonedActivities: 0,
        frustrationIndicators: 0,
      ),
      actionableInsights: ActionableInsights(
        forParents: [],
        forDoctors: [],
      ),
      totalEventsAnalyzed: 0,
    );
  }
}

class ReportMetadata {
  final String reportId;
  final String childId;
  final String sessionId;
  final String date;

  ReportMetadata({
    required this.reportId,
    required this.childId,
    required this.sessionId,
    required this.date,
  });

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      reportId: json['reportId'] as String? ?? 'RPT_UNKNOWN',
      childId: json['childId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      date: json['date'] as String? ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'childId': childId,
    'sessionId': sessionId,
    'date': date,
  };
}

class SessionSummary {
  final double durationMinutes;
  final int activitiesCompleted;
  final String overallEngagement; // "Low" | "Moderate" | "High"

  SessionSummary({
    required this.durationMinutes,
    required this.activitiesCompleted,
    required this.overallEngagement,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      activitiesCompleted: (json['activitiesCompleted'] as num?)?.toInt() ?? 0,
      overallEngagement: json['overallEngagement'] as String? ?? 'Moderate',
    );
  }

  Map<String, dynamic> toJson() => {
    'durationMinutes': durationMinutes,
    'activitiesCompleted': activitiesCompleted,
    'overallEngagement': overallEngagement,
  };
}

class SensoryAndAttention {
  final double visualEngagementScore; // 0-100
  final int distractionEvents;
  final double screenGazeAlignment; // 0-100% looking at screen
  final double focusStability; // 0-100% concentration stability index
  final List<String> sensoryPreferences;

  SensoryAndAttention({
    required this.visualEngagementScore,
    required this.distractionEvents,
    this.screenGazeAlignment = 0.0,
    this.focusStability = 0.0,
    required this.sensoryPreferences,
  });

  factory SensoryAndAttention.fromJson(Map<String, dynamic> json) {
    return SensoryAndAttention(
      visualEngagementScore: (json['visualEngagementScore'] as num?)?.toDouble() ?? 0.0,
      distractionEvents: (json['distractionEvents'] as num?)?.toInt() ?? 0,
      screenGazeAlignment: (json['screenGazeAlignment'] as num?)?.toDouble() ?? 0.0,
      focusStability: (json['focusStability'] as num?)?.toDouble() ?? 0.0,
      sensoryPreferences: (json['sensoryPreferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'visualEngagementScore': visualEngagementScore,
    'distractionEvents': distractionEvents,
    'screenGazeAlignment': screenGazeAlignment,
    'focusStability': focusStability,
    'sensoryPreferences': sensoryPreferences,
  };
}

class SpeechAndCommunication {
  final int totalVocalizations;
  final double pronunciationAccuracy; // 0-100
  final List<String> successfulWords;
  final double averageResponseDelaySeconds;
  final int mouthMovementDetectedCount;
  final double lipMovementActivePercent; // 0-100%

  SpeechAndCommunication({
    required this.totalVocalizations,
    required this.pronunciationAccuracy,
    required this.successfulWords,
    required this.averageResponseDelaySeconds,
    this.mouthMovementDetectedCount = 0,
    this.lipMovementActivePercent = 0.0,
  });

  factory SpeechAndCommunication.fromJson(Map<String, dynamic> json) {
    return SpeechAndCommunication(
      totalVocalizations: (json['totalVocalizations'] as num?)?.toInt() ?? 0,
      pronunciationAccuracy: (json['pronunciationAccuracy'] as num?)?.toDouble() ?? 0.0,
      successfulWords: (json['successfulWords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageResponseDelaySeconds:
          (json['averageResponseDelaySeconds'] as num?)?.toDouble() ?? 0.0,
      mouthMovementDetectedCount:
          (json['mouthMovementDetectedCount'] as num?)?.toInt() ?? 0,
      lipMovementActivePercent:
          (json['lipMovementActivePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalVocalizations': totalVocalizations,
    'pronunciationAccuracy': pronunciationAccuracy,
    'successfulWords': successfulWords,
    'averageResponseDelaySeconds': averageResponseDelaySeconds,
    'mouthMovementDetectedCount': mouthMovementDetectedCount,
    'lipMovementActivePercent': lipMovementActivePercent,
  };
}

class CognitiveAndMotorSkills {
  final double memory; // 0-100
  final double sequencing; // 0-100
  final double fineMotorControl; // 0-100
  final List<String> areasOfStruggle;

  CognitiveAndMotorSkills({
    required this.memory,
    required this.sequencing,
    required this.fineMotorControl,
    required this.areasOfStruggle,
  });

  factory CognitiveAndMotorSkills.fromJson(Map<String, dynamic> json) {
    return CognitiveAndMotorSkills(
      memory: (json['memory'] as num?)?.toDouble() ?? 0.0,
      sequencing: (json['sequencing'] as num?)?.toDouble() ?? 0.0,
      fineMotorControl: (json['fineMotorControl'] as num?)?.toDouble() ?? 0.0,
      areasOfStruggle: (json['areasOfStruggle'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'memory': memory,
    'sequencing': sequencing,
    'fineMotorControl': fineMotorControl,
    'areasOfStruggle': areasOfStruggle,
  };
}

class BehavioralObservations {
  final int hintsRequested;
  final int abandonedActivities;
  final int frustrationIndicators;

  BehavioralObservations({
    required this.hintsRequested,
    required this.abandonedActivities,
    required this.frustrationIndicators,
  });

  factory BehavioralObservations.fromJson(Map<String, dynamic> json) {
    return BehavioralObservations(
      hintsRequested: (json['hintsRequested'] as num?)?.toInt() ?? 0,
      abandonedActivities: (json['abandonedActivities'] as num?)?.toInt() ?? 0,
      frustrationIndicators: (json['frustrationIndicators'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hintsRequested': hintsRequested,
    'abandonedActivities': abandonedActivities,
    'frustrationIndicators': frustrationIndicators,
  };
}

class ActionableInsights {
  final List<String> forParents;
  final List<String> forDoctors;

  ActionableInsights({
    required this.forParents,
    required this.forDoctors,
  });

  factory ActionableInsights.fromJson(Map<String, dynamic> json) {
    return ActionableInsights(
      forParents: (json['forParents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      forDoctors: (json['forDoctors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'forParents': forParents,
    'forDoctors': forDoctors,
  };
}
