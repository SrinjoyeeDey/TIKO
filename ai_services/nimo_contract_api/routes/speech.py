"""
POST /analyze/speech
Accepts a .wav / audio file and target phrase, returns SPEECH_ANALYSIS event JSON.
Handles:
  - Voice tracking & multi-accent recognition (Google STT with en-IN, en-US, hi-IN fallbacks)
  - Dynamic audio normalization & noise filtering via ffmpeg
  - Slurring / Lisping / phonetic normalization (Totla & Indian accents)
  - High accuracy token-level and sequence pronunciation scoring (0–100)
"""
import io
import logging
import re
import subprocess
import time
from difflib import SequenceMatcher
from datetime import datetime, timezone
from typing import List, Protocol, cast

from fastapi import APIRouter, UploadFile, File, Form
from speech_recognition import AudioData, AudioFile, Recognizer, RequestError, UnknownValueError

from ..schemas import SpeechAnalysisEvent, SpeechData

router = APIRouter()
logger = logging.getLogger(__name__)


def convert_to_pcm_wav(audio_bytes: bytes) -> bytes:
    """
    Converts any audio payload (WebM/Opus, OGG, AAC, MP3, WAV at any sample rate)
    into clean, normalized 16kHz mono 16-bit PCM WAV with dynamic audio leveling.
    """
    if not audio_bytes or len(audio_bytes) < 16:
        return audio_bytes

    try:
        # Run ffmpeg normalization: 16kHz mono pcm_s16le with dynamic normalization & noise gate
        process = subprocess.run(
            [
                "ffmpeg",
                "-threads", "1",
                "-i", "pipe:0",
                "-af", "highpass=f=80,lowpass=f=7500,dynaudnorm=f=150:g=15:m=30,volume=2.5",
                "-f", "wav",
                "-acodec", "pcm_s16le",
                "-ar", "16000",
                "-ac", "1",
                "pipe:1",
                "-y",
                "-loglevel", "error",
            ],
            input=audio_bytes,
            capture_output=True,
            timeout=8,
        )
        if process.returncode == 0 and process.stdout and process.stdout.startswith(b"RIFF"):
            return process.stdout
    except Exception as e:
        logger.warning("ffmpeg audio conversion fallback: %s", e)

    return audio_bytes


class GoogleRecognizer(Protocol):
    """The dynamically attached Google recognizer API."""

    def recognize_google(self, audio_data: AudioData, *, language: str) -> str:
        ...


def _normalize_phonetics(text: str) -> str:
    """
    Phonetic & accent normalization:
    - Common Indian transliteration variations (Subhas/Subhash, Netaji/Neta ji, etc.)
    - Common childhood lisping/slurring substitutions (totla speech)
    - Punctuation & whitespace normalization
    """
    if not text:
        return ""

    t = text.lower().strip()
    # Normalize common Indian names / historical words
    substitutions = {
        r"\bnetaji\b": "neta ji",
        r"\bsubash\b": "subhas",
        r"\bsubhash\b": "subhas",
        r"\bchander\b": "chandra",
        r"\bjay hind\b": "jai hind",
        r"\bjayhind\b": "jai hind",
        r"\bjaihind\b": "jai hind",
        r"\baazadi\b": "azadi",
        r"\bazadhi\b": "azadi",
        r"\binquilab\b": "inquilab",
        r"\binqilab\b": "inquilab",
    }
    for pattern, repl in substitutions.items():
        t = re.sub(pattern, repl, t)

    # Phonetic substitutions for lisp / slurring
    lisp_map = {
        "ph": "f",
        "w": "r",
        "th": "f",
        "z": "s",
        "d": "t",
        "sh": "s",
    }
    for k, v in lisp_map.items():
        t = t.replace(k, v)

    # Remove all punctuation and normalize spaces
    t = re.sub(r"[^\w\s]", " ", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _calculate_accuracy(user_text: str, target_text: str) -> int:
    """
    Returns pronunciation accuracy as 0–100 integer.
    Combines exact match, phonetic normalization, fuzzy sequence matching,
    and token-level overlap.
    """
    if not user_text or not target_text:
        return 0

    u_raw = re.sub(r"[^\w\s]", " ", user_text.lower()).strip()
    u_raw = re.sub(r"\s+", " ", u_raw)
    t_raw = re.sub(r"[^\w\s]", " ", target_text.lower()).strip()
    t_raw = re.sub(r"\s+", " ", t_raw)

    if u_raw == t_raw:
        return 100

    u_norm = _normalize_phonetics(u_raw)
    t_norm = _normalize_phonetics(t_raw)

    if u_norm == t_norm or t_raw in u_raw or t_norm in u_norm:
        return 96

    # Sequence similarity
    seq_ratio = SequenceMatcher(None, u_norm, t_norm).ratio()

    # Token overlap & fuzzy word matching
    u_tokens = [w for w in u_norm.split() if w]
    t_tokens = [w for w in t_norm.split() if w]

    if not t_tokens:
        return int(round(seq_ratio * 100))

    matched_count = 0.0
    for tw in t_tokens:
        if tw in u_tokens:
            matched_count += 1.0
        else:
            best_match = max([SequenceMatcher(None, tw, uw).ratio() for uw in u_tokens], default=0.0)
            if best_match >= 0.70:
                matched_count += best_match
            elif best_match >= 0.50:
                matched_count += best_match * 0.7

    token_score = matched_count / len(t_tokens)
    final_score = (seq_ratio * 0.35) + (token_score * 0.65)
    return max(0, min(100, int(round(final_score * 100))))


@router.post("/speech", response_model=SpeechAnalysisEvent)
async def analyze_speech(
    file: UploadFile = File(...),
    childId:    str = Form("A001"),
    sessionId:  str = Form("SES_001"),
    activityId: str = Form("netaji_voice_01"),
    targetPhrase: str = Form("")
):
    """
    Analyzes uploaded audio and returns a standardized SPEECH_ANALYSIS event.
    Uses multi-language fallback (en-IN -> en-US -> hi-IN -> en-GB) for robust recognition.
    """
    start_time = time.time()
    recognizer = Recognizer()

    transcript     = ""
    speech_detected = False
    speech_attempt  = False
    confidence      = 0.0

    try:
        raw_audio_bytes = await file.read()
        if not raw_audio_bytes or len(raw_audio_bytes) < 16:
            raise ValueError("Audio payload too small or empty")

        # Convert incoming audio to 16kHz mono PCM WAV with audio leveling
        wav_bytes = convert_to_pcm_wav(raw_audio_bytes)

        audio_source = AudioFile(io.BytesIO(wav_bytes))
        with audio_source as source:
            # Record full audio without ambient noise pre-read (which truncates the start of speech)
            audio_data = recognizer.record(source)

        google_recognizer = cast(GoogleRecognizer, recognizer)
        
        # Multi-language recognition ladder: Indian English -> US English -> Hindi -> British English
        languages_to_try: List[str] = ["en-IN", "en-US", "hi-IN", "en-GB"]
        best_transcript = ""
        best_accuracy = -1

        for lang in languages_to_try:
            try:
                candidate = google_recognizer.recognize_google(audio_data, language=lang)
                if candidate and candidate.strip():
                    candidate_clean = candidate.strip()
                    speech_detected = True
                    speech_attempt = True
                    confidence = max(confidence, 0.90)

                    if targetPhrase:
                        acc = _calculate_accuracy(candidate_clean, targetPhrase)
                        if acc > best_accuracy:
                            best_accuracy = acc
                            best_transcript = candidate_clean
                            if acc >= 85:
                                # High accuracy found, stop early
                                break
                    else:
                        best_transcript = candidate_clean
                        break
            except UnknownValueError:
                speech_attempt = True
                continue
            except RequestError as error:
                logger.warning("Google speech request error for lang %s: %s", lang, error)
                continue

        if best_transcript:
            transcript = best_transcript
        elif speech_attempt:
            # Speech was heard by recorder but no clear word transcribed
            confidence = 0.0

    except (OSError, ValueError, Exception) as error:
        logger.warning("Speech analysis processing note: %s", error)

    response_time       = round(time.time() - start_time, 2)
    pronunciation_score = _calculate_accuracy(transcript, targetPhrase) if (targetPhrase and transcript) else 0

    data = SpeechData(
        transcript        = transcript,
        speechDetected    = speech_detected,
        speechAttempt     = speech_attempt,
        pronunciationScore= pronunciation_score,
        responseTime      = response_time,
        confidence        = confidence
    )

    return SpeechAnalysisEvent(
        source     = "python_speech",
        eventType  = "SPEECH_ANALYSIS",
        childId    = childId,
        sessionId  = sessionId,
        activityId = activityId,
        timestamp  = datetime.now(timezone.utc).isoformat(),
        data       = data
    )
