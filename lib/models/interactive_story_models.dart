/// Data models for the Indian History Storytelling Experience.
class SceneChoice {
  final String label;
  final String nextSceneId;

  const SceneChoice({
    required this.label,
    required this.nextSceneId,
  });
}

class StoryScene {
  final String id;
  final String narrativeText;
  final String? imagePath;
  final String? historicalFact;
  final List<SceneChoice>? choices;

  const StoryScene({
    required this.id,
    required this.narrativeText,
    this.imagePath,
    this.historicalFact,
    this.choices,
  });
}

class StoryData {
  final String id;
  final String stateId;
  final String title;
  final String subtitle;
  final String taglineOrQuote;
  final String imagePath;
  final List<StoryScene> scenes;
  bool isCompleted;

  StoryData({
    required this.id,
    required this.stateId,
    required this.title,
    required this.subtitle,
    required this.taglineOrQuote,
    required this.imagePath,
    required this.scenes,
    this.isCompleted = false,
  });
}

class StateStoriesCollection {
  final String stateId;
  final String stateName;
  final String tagline;
  final String atmosphericImage;
  final List<StoryData> stories;

  const StateStoriesCollection({
    required this.stateId,
    required this.stateName,
    required this.tagline,
    required this.atmosphericImage,
    required this.stories,
  });
}
