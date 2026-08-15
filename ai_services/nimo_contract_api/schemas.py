"""
Pydantic schemas strictly matching the NIMO Integration Contract
defined by the backend team.
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


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
    targetPhrase: Optional[str] = ""  # What the child was supposed to say


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
