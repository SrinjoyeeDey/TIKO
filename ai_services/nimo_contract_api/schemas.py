"""
Pydantic schemas strictly matching the NIMO Integration Contract
defined by the backend team and AI microservices.
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

# ─── Shared Event Wrapper ────────────────────────────────────────────────────

class NIMOEvent(BaseModel):
    source: str
    eventType: str
    childId: str
    sessionId: str
    activityId: str
    timestamp: str


# ─── Speech ──────────────────────────────────────────────────────────────────

class SpeechRequest(BaseModel):
    childId: str
    sessionId: str
    activityId: str
    targetPhrase: Optional[str] = ""


class SpeechData(BaseModel):
    transcript: str
    speechDetected: bool
    speechAttempt: bool
    pronunciationScore: int    # 0 – 100
    responseTime: float        # seconds taken
    confidence: float          # 0.0 – 1.0


class SpeechAnalysisEvent(NIMOEvent):
    data: SpeechData


# ─── Engagement ──────────────────────────────────────────────────────────────

class EngagementRequest(BaseModel):
    childId: str
    sessionId: str
    activityId: str


class EngagementData(BaseModel):
    faceDetected: bool
    lookingAtScreen: bool
    mouthMovement: bool
    engagementScore: int       # 0 – 100


class EngagementAnalysisEvent(NIMOEvent):
    data: EngagementData


# ─── Engagement Summary (Aggregated, sent end-of-session) ────────────────────

class EngagementSummaryData(BaseModel):
    duration: float                    # Total seconds of session
    facePresentPercentage: float       # 0 – 100
    screenFocusPercentage: float       # 0 – 100
    distractionCount: int


class EngagementSummaryEvent(NIMOEvent):
    data: EngagementSummaryData


# ─── Sign-Up Difficulty Assessment (Groq / LangChain Structured Output) ──────

class DifficultyRequest(BaseModel):
    childId: Optional[str] = "child_001"
    name: str
    age: int
    standard: str  # e.g., "Nursery", "LKG", "UKG", "Grade 1", "Grade 2", etc.
    language: Optional[str] = "en"
    learningPace: Optional[str] = "normal"  # "gentle", "normal", "fast"
    interests: Optional[str] = "stories, puzzles, discovery"


class DifficultyOutput(BaseModel):
    """Structured output returned by Groq LLM via LangChain."""
    difficultyPercentage: int = Field(
        ...,
        description="The calculated quest difficulty percentage integer between 10 and 95 (e.g. 30 for 5yo in LKG/Nursery, 40 for 5yo in UKG, 50 for 5yo in Grade 1, 60 for 6yo in Grade 2, 75 for 8yo in Grade 3)."
    )
    difficultyLevel: Optional[str] = Field(
        default="Balanced Explorer",
        description="Descriptive difficulty label e.g. Gentle Starter, Balanced Explorer, Curious Adventurer, Challenger, Champion"
    )
    reasoning: Optional[str] = Field(
        default="",
        description="Brief 1-sentence cognitive explanation of the difficulty calibration."
    )


class DifficultyResponse(BaseModel):
    success: bool
    childId: str
    difficultyPercentage: int  # Structured integer percentage value from LLM (stored into SQLite)
    difficultyLevel: Optional[str] = "Balanced Explorer"
    reasoning: Optional[str] = ""
    modelUsed: Optional[str] = "groq/llama-3.1-8b-instant (LangChain)"


# ─── Post-Level Adaptive Session Evaluation ──────────────────────────────────

class AdaptiveSessionEvaluationRequest(BaseModel):
    childId: str
    name: Optional[str] = "Explorer"
    age: Optional[int] = 6
    standard: Optional[str] = "Grade 1"
    chapterId: Optional[str] = "Netaji"
    levelId: Optional[str] = "Netaji_0"
    currentAbility: Optional[str] = "High Comprehension"
    previousPerformance: Optional[str] = "3 stars, 100% accuracy"
    preferredInteraction: Optional[str] = "Strong visual gaze lock & clear verbal repetition"
    speechAbility: Optional[str] = "85% pronunciation accuracy across vocal prompts"
    motorPerformance: Optional[str] = "Smooth drag-and-drop sequencing without retries"
    attentionPattern: Optional[str] = "90% screen gaze alignment, 0 distraction events"
    learningHistory: Optional[str] = "Level completed in 1.5 mins, 0 hints used"
    currentDifficultyPercentage: Optional[int] = 50


class AdaptiveDifficultyOutput(BaseModel):
    """Structured output returned by Groq LLM after clinical session evaluation."""
    difficultyPercentage: int = Field(
        ...,
        description="Calculated updated quest difficulty percentage integer between 10 and 95 for the next learning session."
    )
    difficultyLevel: Optional[str] = Field(
        default="Curious Adventurer",
        description="Descriptive difficulty label e.g. Gentle Starter, Balanced Explorer, Curious Adventurer, Challenger, Champion"
    )
    reasoning: Optional[str] = Field(
        default="",
        description="Pediatric clinical explanation detailing how the child's speech, motor, attention, and learning metrics shaped the updated difficulty."
    )
    recommendationsForNextSession: Optional[List[str]] = Field(
        default_factory=list,
        description="2-3 actionable learning suggestions for parents and teachers for the next session."
    )


class AdaptiveDifficultyResponse(BaseModel):
    success: bool
    childId: str
    difficultyPercentage: int
    difficultyLevel: str
    reasoning: str
    recommendationsForNextSession: List[str]
    modelUsed: str


# ─── Dynamic AI Voice Interactions (ElevenLabs & Groq) ───────────────────────

class VoiceInteractionRequest(BaseModel):
    interactionType: str  # "POST_SIGNUP_INTRO", "READ_QUESTION", "PRONOUNCE_PHRASE", "RETRY_QUESTION", "LEVEL_COMPLETION", "CUSTOM"
    childId: Optional[str] = "child_001"
    childName: Optional[str] = "Explorer"
    childAge: Optional[int] = 6
    difficultyLevel: Optional[str] = "Balanced Explorer"
    chapterId: Optional[str] = None
    chapterName: Optional[str] = None
    levelId: Optional[str] = None
    levelName: Optional[str] = None
    availableChapters: Optional[List[str]] = Field(default_factory=list)
    questionId: Optional[int] = None
    questionNumber: Optional[int] = None
    questionText: Optional[str] = None
    questionType: Optional[str] = None
    options: Optional[Any] = None  # Dict or List of options
    targetPhrase: Optional[str] = None
    retryCount: Optional[int] = 1
    stars: Optional[int] = None
    totalCorrect: Optional[int] = None
    totalQuestions: Optional[int] = None
    customText: Optional[str] = None
    voiceId: Optional[str] = None


class VoiceInteractionResponse(BaseModel):
    success: bool
    interactionType: str
    spokenText: str
    audioId: Optional[str] = None
    audioUrl: Optional[str] = None
    audioBase64: Optional[str] = None
    audioFormat: str = "audio/mpeg"
    ttsStatus: str
    modelUsed: str


class TTSRequest(BaseModel):
    text: str
    voiceId: Optional[str] = None
    stability: Optional[float] = 0.55
    similarityBoost: Optional[float] = 0.80


class TTSResponse(BaseModel):
    success: bool
    audioId: str
    audioUrl: str
    audioBase64: Optional[str] = None
    audioFormat: str = "audio/mpeg"
    status: str


class VoiceStatusResponse(BaseModel):
    status: str
    elevenlabsConfigured: bool
    groqConfigured: bool
    defaultVoiceId: str
    cachedAudioCount: int

