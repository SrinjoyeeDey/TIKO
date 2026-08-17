"""
Voice Interaction API Routes
============================
Endpoints:
  POST /voice/interaction   - Dynamic text dialogue generation + ElevenLabs TTS speech synthesis
  POST /voice/tts           - Direct text-to-speech synthesis via ElevenLabs
  GET  /voice/audio/{id}    - Stream cached synthesized MP3 audio
  GET  /voice/status        - Connectivity status of voice and TTS services
"""

import os
import base64
import logging
from pathlib import Path
from fastapi import APIRouter, Request, HTTPException, Response

from ..schemas import (
    VoiceInteractionRequest,
    VoiceInteractionResponse,
    TTSRequest,
    TTSResponse,
    VoiceStatusResponse,
)
from ..services.elevenlabs_service import elevenlabs_service
from ..services.voice_service import voice_service

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/interaction", response_model=VoiceInteractionResponse)
async def process_voice_interaction(req: VoiceInteractionRequest, request: Request):
    """
    Unified dynamic child-facing voice interaction endpoint:
    - POST_SIGNUP_INTRO: Welcomes the child using discovered chapters and profile.
    - READ_QUESTION: Reads currently active question text & options accurately.
    - PRONOUNCE_PHRASE: Pronounces the target phrase via ElevenLabs with clear articulation.
    - RETRY_QUESTION: Gives state-aware encouragement using active question data.
    - LEVEL_COMPLETION: Congratulates based strictly on actual stars and completed level data.
    """
    # Derive host/port base URL for streaming audio
    base_url = str(request.base_url).rstrip("/")
    # Fallback to localhost:8001 if header is internal or 0.0.0.0
    if "0.0.0.0" in base_url or "127.0.0.1" in base_url:
        base_url = "http://localhost:8001"

    try:
        return voice_service.process_interaction(req, base_url=base_url)
    except Exception as e:
        logger.error(f"Voice interaction failed: {e}", exc_info=True)
        # Graceful fallback response
        fallback_text = req.customText or req.questionText or req.targetPhrase or "Let's explore together!"
        return VoiceInteractionResponse(
            success=False,
            interactionType=req.interactionType,
            spokenText=fallback_text,
            ttsStatus=f"Error: {str(e)}",
            modelUsed="Offline Heuristic",
        )


@router.post("/tts", response_model=TTSResponse)
async def synthesize_tts(req: TTSRequest, request: Request):
    """Direct Text-to-Speech synthesis via ElevenLabs with caching."""
    base_url = str(request.base_url).rstrip("/")
    if "0.0.0.0" in base_url or "127.0.0.1" in base_url:
        base_url = "http://localhost:8001"

    audio_bytes, audio_id, status = elevenlabs_service.synthesize(
        text=req.text,
        voice_id=req.voiceId,
        stability=req.stability or 0.55,
        similarity_boost=req.similarityBoost or 0.80,
    )

    if not audio_bytes and status != "cached":
        raise HTTPException(
            status_code=502,
            detail=f"TTS synthesis failed: {status}",
        )

    audio_url = f"{base_url}/voice/audio/{audio_id}"
    audio_b64 = base64.b64encode(audio_bytes).decode("utf-8") if (audio_bytes and len(audio_bytes) < 400000) else None

    return TTSResponse(
        success=True,
        audioId=audio_id,
        audioUrl=audio_url,
        audioBase64=audio_b64,
        audioFormat="audio/mpeg",
        status=status,
    )


@router.get("/audio/{audio_id}")
async def get_audio_stream(audio_id: str):
    """Streams cached MP3 audio bytes by audio_id."""
    clean_id = Path(audio_id).stem
    audio_bytes = elevenlabs_service.get_cached_audio(clean_id)

    if not audio_bytes:
        raise HTTPException(
            status_code=404,
            detail=f"Audio '{clean_id}' not found in cache.",
        )

    return Response(
        content=audio_bytes,
        media_type="audio/mpeg",
        headers={
            "Content-Disposition": f'inline; filename="{clean_id}.mp3"',
            "Accept-Ranges": "bytes",
            "Cache-Control": "public, max-age=86400",
        },
    )


@router.get("/status", response_model=VoiceStatusResponse)
async def get_voice_status():
    """Returns connectivity and configuration status of voice engines."""
    from ..services.elevenlabs_service import _MEMORY_AUDIO_CACHE, _CACHE_DIR
    disk_count = len(list(_CACHE_DIR.glob("*.mp3"))) if _CACHE_DIR.exists() else 0
    total_cache = max(len(_MEMORY_AUDIO_CACHE), disk_count)

    return VoiceStatusResponse(
        status="online",
        elevenlabsConfigured=elevenlabs_service.is_configured(),
        groqConfigured=bool(os.environ.get("GROQ_API_KEY", "").strip()),
        defaultVoiceId=elevenlabs_service.default_voice_id,
        cachedAudioCount=total_cache,
    )
