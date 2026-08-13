import 'question.dart';

class MatchingImage {
  final String id;
  final String file;
  final String? label;

  const MatchingImage({
    required this.id,
    required this.file,
    this.label,
  });

  factory MatchingImage.fromJson(Map<String, dynamic> json) {
    return MatchingImage(
      id: json['id'] as String,
      file: json['file'] as String,
      label: json['label'] as String?,
    );
  }
}

class MatchingDescription {
  final String id;
  final String text;

  const MatchingDescription({
    required this.id,
    required this.text,
  });

  factory MatchingDescription.fromJson(Map<String, dynamic> json) {
    return MatchingDescription(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }
}

class ImageMatchingQuestion extends Question {
  final List<MatchingImage> images;
  final List<MatchingDescription> descriptions;
  final Map<String, String> correctMatches;
  final int points;

  const ImageMatchingQuestion({
    required super.id,
    required super.type,
    required super.questionText,
    super.difficulty,
    required this.images,
    required this.descriptions,
    required this.correctMatches,
    required this.points,
  });

  factory ImageMatchingQuestion.fromJson(Map<String, dynamic> json) {
    final imagesList = (json['images'] as List<dynamic>?) ?? [];
    final descriptionsList = (json['descriptions'] as List<dynamic>?) ?? [];
    final matchesMap = (json['correct_matches'] as Map<String, dynamic>?) ?? {};

    return ImageMatchingQuestion(
      id: json['id'] as int,
      type: QuestionType.imageMatching,
      questionText: json['question'] as String,
      difficulty: json['difficulty'] as String?,
      images: imagesList.map((e) => MatchingImage.fromJson(e as Map<String, dynamic>)).toList(),
      descriptions: descriptionsList.map((e) => MatchingDescription.fromJson(e as Map<String, dynamic>)).toList(),
      correctMatches: matchesMap.map((key, value) => MapEntry(key, value as String)),
      points: json['points'] as int? ?? 1,
    );
  }
}
