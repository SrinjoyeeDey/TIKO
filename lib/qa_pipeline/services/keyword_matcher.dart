/// Lightweight keyword-based matching for evaluating descriptive answers.
///
/// This is a placeholder implementation. It can later be replaced with
/// embedding-based semantic similarity without changing the question UI.
class KeywordMatcher {
  /// Default threshold used when none is specified.
  static const double defaultThreshold = 0.60;

  /// Calculates how many [keyConcepts] appear in the [userAnswer].
  ///
  /// Returns a score between 0.0 (no match) and 1.0 (all concepts matched).
  ///
  /// For multi-word concepts like `"poor family"`, all words in the concept
  /// must appear in the user's answer for it to count as matched.
  static double calculateScore(String userAnswer, List<String> keyConcepts) {
    if (keyConcepts.isEmpty) return 1.0;

    final normalizedAnswer = _normalize(userAnswer);
    final answerWords = _tokenize(normalizedAnswer);

    int matchedCount = 0;

    for (final concept in keyConcepts) {
      final conceptWords = _tokenize(_normalize(concept));
      if (conceptWords.isEmpty) continue;

      // A concept is matched if ALL its words appear in the answer.
      final allWordsPresent =
          conceptWords.every((word) => answerWords.contains(word));

      if (allWordsPresent) {
        matchedCount++;
      }
    }

    return matchedCount / keyConcepts.length;
  }

  /// Returns a human-readable label for the given [score].
  static String getScoreLabel(double score) {
    if (score >= 0.80) return 'Excellent understanding';
    if (score >= 0.65) return 'Good understanding';
    if (score >= 0.50) return 'Partially correct';
    return 'Needs improvement';
  }

  /// Whether the [score] meets the given [threshold].
  static bool meetsThreshold(double score, double threshold) {
    return score >= threshold;
  }

  // ─── Private helpers ───────────────────────────────────────────────

  /// Lowercases text and strips punctuation.
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), '') // keep apostrophes for contractions
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Splits normalized text into a set of unique word tokens.
  static Set<String> _tokenize(String normalizedText) {
    return normalizedText
        .split(' ')
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toSet();
  }

  /// Common English stop words to ignore during matching.
  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'has', 'have', 'had', 'do', 'does', 'did', 'will', 'would', 'shall',
    'should', 'may', 'might', 'must', 'can', 'could', 'am', 'i', 'me',
    'my', 'we', 'our', 'you', 'your', 'he', 'him', 'his', 'she', 'her',
    'it', 'its', 'they', 'them', 'their', 'this', 'that', 'these', 'those',
    'of', 'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'as',
    'into', 'about', 'between', 'through', 'and', 'but', 'or', 'so',
    'if', 'then', 'than', 'too', 'very', 'just', 'not', 'no', 'also',
  };
}
