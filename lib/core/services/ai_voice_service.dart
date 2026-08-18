import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'web_audio_helper.dart';

/// Central AI Voice & Text-to-Speech companion service.
/// Orchestrates ElevenLabs audio playback and Groq dynamic dialogues
/// through the local Python AI Microservice (port 8001), with seamless
/// local offline TTS fallback.
class AiVoiceService extends ChangeNotifier {
  AiVoiceService._internal();
  static final AiVoiceService instance = AiVoiceService._internal();

  static String get aiServiceBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://localhost:8001';
  }

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  String? _currentSpokenText;
  String? get currentSpokenText => _currentSpokenText;

  Map<String, dynamic>? _lastInteractionPayload;

  /// Update mute state
  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stop();
    }
    notifyListeners();
  }

  /// Toggle mute state
  void toggleMute() {
    setMuted(!_isMuted);
  }

  /// Stop any active speech or audio playback
  void stop() {
    _isSpeaking = false;
    try {
      WebAudioHelper.cancelSpeech();
    } catch (e) {
      debugPrint('AiVoiceService.stop error: $e');
    }
    notifyListeners();
  }

  /// Replay the most recent speech or interaction
  Future<void> replayCurrent() async {
    if (_lastInteractionPayload != null) {
      await _executeInteraction(_lastInteractionPayload!);
    } else if (_currentSpokenText != null && _currentSpokenText!.isNotEmpty) {
      await _playSpokenTextDirect(_currentSpokenText!);
    }
  }

  /// 1. Play dynamic AI-powered post-signup introduction
  Future<void> playPostSignupIntro({
    required String childName,
    required int age,
    required String difficultyLevel,
    required List<String> availableChapters,
    String? firstChapter,
  }) async {
    final payload = {
      'interactionType': 'POST_SIGNUP_INTRO',
      'childName': childName,
      'childAge': age,
      'difficultyLevel': difficultyLevel,
      'availableChapters': availableChapters,
      'chapterName': firstChapter ?? (availableChapters.isNotEmpty ? availableChapters.first : null),
    };

    final fallback = availableChapters.isNotEmpty
        ? 'Hello $childName! Welcome to NIMO The Warrior! Your adventure begins with ${firstChapter ?? availableChapters.first}. Get ready to discover historical stories and solve exciting quests!'
        : 'Hello $childName! Welcome to NIMO The Warrior! Your learning journey is calibrated for $difficultyLevel. Let\'s begin our interactive quest!';

    await _executeInteraction(payload, fallbackText: fallback);
  }

  /// 2. Play dynamic AI-powered level completion celebration
  Future<void> playLevelCongratulation({
    required String childName,
    required String chapterName,
    required String levelName,
    required int stars,
    required int totalCorrect,
    required int totalQuestions,
  }) async {
    final payload = {
      'interactionType': 'LEVEL_COMPLETION',
      'childName': childName,
      'chapterName': chapterName,
      'levelName': levelName,
      'stars': stars,
      'totalCorrect': totalCorrect,
      'totalQuestions': totalQuestions,
    };

    final starPhrase = stars == 3
        ? 'a perfect 3 stars!'
        : (stars == 2 ? '2 shining stars!' : 'a victory star!');
    final fallback =
        'Hooray $childName! You successfully completed $levelName with $starPhrase Wonderful job on $chapterName!';

    await _executeInteraction(payload, fallbackText: fallback);
  }

  /// 3. Read question prompt & options
  Future<void> readQuestion({
    required String questionText,
    required int questionNumber,
    required String questionType,
    dynamic options,
  }) async {
    final payload = {
      'interactionType': 'READ_QUESTION',
      'questionText': questionText,
      'questionNumber': questionNumber,
      'questionType': questionType,
      'options': options,
    };

    final cleanText = questionText.replaceAll('*', '').replaceAll('#', '').trim();
    String optionsText = '';
    if (options is List && options.isNotEmpty && options.length <= 4) {
      optionsText = ' Options: ' + options.map((e) => e.toString()).join(', ');
    } else if (options is Map && options.isNotEmpty && options.length <= 4) {
      optionsText = ' Options: ' + options.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    final fallback = 'Question $questionNumber. $cleanText$optionsText';

    await _executeInteraction(payload, fallbackText: fallback);
  }

  /// 4. Pronounce specific word or target phrase clearly
  Future<void> pronounceWord({
    required String targetPhrase,
    String? context,
  }) async {
    final payload = {
      'interactionType': 'PRONOUNCE_PHRASE',
      'targetPhrase': targetPhrase,
      'questionText': context,
    };

    final fallback = targetPhrase.trim().isNotEmpty ? targetPhrase.trim() : 'Please listen carefully.';
    await _executeInteraction(payload, fallbackText: fallback);
  }

  /// 5. Play state-aware retry prompt
  Future<void> playRetryPrompt({
    String? targetPhrase,
    String? questionText,
    int retryCount = 1,
  }) async {
    final payload = {
      'interactionType': 'RETRY_QUESTION',
      'targetPhrase': targetPhrase,
      'questionText': questionText,
      'retryCount': retryCount,
    };

    String fallback;
    final phrase = targetPhrase?.trim() ?? '';
    if (phrase.isNotEmpty) {
      fallback = retryCount > 1
          ? 'Let\'s try one more time! Listen carefully and repeat: $phrase'
          : 'Nice try! Listen carefully and say: $phrase';
    } else if (questionText != null && questionText.trim().isNotEmpty) {
      fallback = 'Let\'s try again! ${questionText.trim()}';
    } else {
      fallback = 'You can do it! Give it another try!';
    }

    await _executeInteraction(payload, fallbackText: fallback);
  }

  /// 6. Speak custom freeform text
  Future<void> speakCustomText(String text) async {
    final payload = {
      'interactionType': 'CUSTOM',
      'customText': text,
    };
    await _executeInteraction(payload, fallbackText: text);
  }

  /// Internal handler: sends voice interaction request to Python AI Microservice (Port 8001)
  /// and triggers synthesized MP3 stream or Web Speech fallback.
  Future<void> _executeInteraction(
    Map<String, dynamic> payload, {
    String? fallbackText,
  }) async {
    if (_isMuted) return;

    _lastInteractionPayload = Map<String, dynamic>.from(payload);
    final fallback = fallbackText ??
        (payload['customText'] ?? payload['questionText'] ?? payload['targetPhrase'] ?? 'Let\'s learn together!')
            .toString();

    // Set initial speaking state
    _currentSpokenText = fallback;
    _isSpeaking = true;
    notifyListeners();

    final url = Uri.parse('$aiServiceBaseUrl/voice/interaction');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final spokenText = (body['spokenText'] as String?) ?? fallback;
        final audioUrl = body['audioUrl'] as String?;
        final audioB64 = body['audioBase64'] as String?;

        _currentSpokenText = spokenText;
        notifyListeners();

        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('AiVoiceService: Streaming audio from $audioUrl');
          WebAudioHelper.playAudioSource(audioUrl, () {
            _isSpeaking = false;
            notifyListeners();
          });
          return;
        } else if (audioB64 != null && audioB64.isNotEmpty) {
          debugPrint('AiVoiceService: Playing audio from Base64 data URI');
          WebAudioHelper.playAudioSource('data:audio/mpeg;base64,$audioB64', () {
            _isSpeaking = false;
            notifyListeners();
          });
          return;
        } else {
          // Speak received text via Web speech synthesis
          _playSpokenTextDirect(spokenText);
          return;
        }
      }
    } catch (e) {
      debugPrint('AiVoiceService: Python voice service unreachable or error: $e');
    }

    // Fallback: speak fallback text directly via Web TTS
    _playSpokenTextDirect(fallback);
  }

  Future<void> _playSpokenTextDirect(String text) async {
    if (_isMuted) return;
    _currentSpokenText = text;
    _isSpeaking = true;
    notifyListeners();

    try {
      WebAudioHelper.speakText(text, () {
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AiVoiceService: direct speak error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }
}
