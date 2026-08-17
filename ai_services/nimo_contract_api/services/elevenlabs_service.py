"""
ElevenLabs Text-to-Speech (TTS) Service
=======================================
Handles server-side voice synthesis using ElevenLabs API.
- Reads `ELEVENLABS_API_KEY` from `ai_services/.env` or root `.env`.
- Caches generated audio in-memory and on disk to optimize latency and minimize API usage.
- Provides fallback handling for network errors, rate limits, and quota issues.
"""

import os
import hashlib
import logging
from pathlib import Path
from typing import Optional, Tuple
import requests
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

# Load environment variables
_current_dir = Path(__file__).resolve().parent
_ai_services_dir = _current_dir.parent.parent
_workspace_root = _ai_services_dir.parent

_ai_services_env = _ai_services_dir / ".env"
_root_env = _workspace_root / ".env"

if _ai_services_env.exists():
    load_dotenv(_ai_services_env)
elif _root_env.exists():
    load_dotenv(_root_env)
else:
    load_dotenv()

# Cache directory for synthesized audio
_CACHE_DIR = _ai_services_dir / ".audio_cache"
_CACHE_DIR.mkdir(parents=True, exist_ok=True)

# In-memory LRU-like cache
_MEMORY_AUDIO_CACHE = {}

# Default voice settings (Warm, clear, child-friendly English narrator)
DEFAULT_VOICE_ID = os.environ.get("ELEVENLABS_VOICE_ID", "21m00Tcm4TlvDq8ikWAM")  # "Rachel" - warm & friendly
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/text-to-speech"


class ElevenLabsService:
    """Server-side ElevenLabs Text-to-Speech provider with intelligent caching."""

    def __init__(self):
        self.api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
        self.default_voice_id = DEFAULT_VOICE_ID

    def get_api_key(self) -> str:
        if _ai_services_env.exists():
            load_dotenv(_ai_services_env, override=True)
        self.api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
        return self.api_key

    def is_configured(self) -> bool:
        return bool(self.get_api_key())

    def _get_cache_key(self, text: str, voice_id: str) -> str:
        """Generates deterministic hash key for cached audio."""
        raw = f"{voice_id}:{text.strip().lower()}"
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    def get_cached_audio(self, audio_id: str) -> Optional[bytes]:
        """Retrieves cached audio bytes from memory or disk."""
        if audio_id in _MEMORY_AUDIO_CACHE:
            return _MEMORY_AUDIO_CACHE[audio_id]

        file_path = _CACHE_DIR / f"{audio_id}.mp3"
        if file_path.exists():
            try:
                audio_bytes = file_path.read_bytes()
                _MEMORY_AUDIO_CACHE[audio_id] = audio_bytes
                return audio_bytes
            except Exception as e:
                logger.warning(f"Failed to read disk audio cache {file_path}: {e}")

        return None

    def store_audio_cache(self, audio_id: str, audio_bytes: bytes) -> None:
        """Stores audio in memory and on disk."""
        _MEMORY_AUDIO_CACHE[audio_id] = audio_bytes
        try:
            file_path = _CACHE_DIR / f"{audio_id}.mp3"
            file_path.write_bytes(audio_bytes)
        except Exception as e:
            logger.warning(f"Failed to save audio to disk cache: {e}")

    def synthesize(
        self,
        text: str,
        voice_id: Optional[str] = None,
        stability: float = 0.55,
        similarity_boost: float = 0.80,
    ) -> Tuple[Optional[bytes], str, str]:
        """Synthesizes speech for the provided text."""
        return self.synthesize_speech(
            text=text,
            voice_id=voice_id,
            stability=stability,
            similarity_boost=similarity_boost,
        )

    def get_audio_hash(self, text: str, voice_id: str) -> str:
        return self._get_cache_key(text, voice_id)

    def get_default_voice_id(self) -> str:
        return self.default_voice_id

    def _synthesize_fallback(self, text: str, audio_id: str) -> Optional[bytes]:
        """
        Synthesize high-quality fallback speech using edge-tts or gTTS
        when ElevenLabs API key is missing, invalid, or rate-limited.
        """
        # 1. Try edge-tts (High definition neural voice)
        try:
            import asyncio
            import edge_tts

            async def _run_edge():
                communicate = edge_tts.Communicate(text, "en-US-AnaNeural")
                out = bytearray()
                async for chunk in communicate.stream():
                    if chunk["type"] == "audio":
                        out.extend(chunk["data"])
                return bytes(out)

            try:
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    import concurrent.futures
                    with concurrent.futures.ThreadPoolExecutor() as pool:
                        audio_bytes = pool.submit(asyncio.run, _run_edge()).result()
                else:
                    audio_bytes = loop.run_until_complete(_run_edge())
            except Exception:
                audio_bytes = asyncio.run(_run_edge())

            if audio_bytes and len(audio_bytes) > 100:
                self.store_audio_cache(audio_id, audio_bytes)
                logger.info(f"Fallback Neural TTS successfully synthesized {len(audio_bytes)} bytes for audio_id {audio_id[:8]}")
                return audio_bytes
        except Exception as e:
            logger.warning(f"edge-tts fallback warning: {e}")

        # 2. Try gTTS fallback
        try:
            from gtts import gTTS
            import io
            tts = gTTS(text=text, lang="en", slow=False)
            fp = io.BytesIO()
            tts.write_to_fp(fp)
            audio_bytes = fp.getvalue()
            if audio_bytes and len(audio_bytes) > 100:
                self.store_audio_cache(audio_id, audio_bytes)
                logger.info(f"gTTS fallback successfully synthesized {len(audio_bytes)} bytes for audio_id {audio_id[:8]}")
                return audio_bytes
        except Exception as e:
            logger.warning(f"gTTS fallback warning: {e}")

        return None

    def synthesize_speech(
        self,
        text: str,
        voice_id: Optional[str] = None,
        stability: float = 0.55,
        similarity_boost: float = 0.85,
    ) -> Tuple[Optional[bytes], str, str]:
        """
        Synthesizes text to speech using ElevenLabs API with dual-tier caching.
        Automatically falls back to local Neural TTS if ElevenLabs key is invalid or fails.
        """
        clean_text = text.strip()
        if not clean_text:
            return None, "", "Empty text provided"

        chosen_voice_id = voice_id or self.get_default_voice_id()
        audio_id = self.get_audio_hash(clean_text, chosen_voice_id)

        # 1. Check Cache
        cached_audio = self.get_cached_audio(audio_id)
        if cached_audio:
            logger.info(f"Audio cache hit for audio_id {audio_id[:8]}")
            return cached_audio, audio_id, "cached"

        # 2. Check API Key
        key = self.get_api_key()
        if key and len(key) >= 20:
            # 3. Call ElevenLabs API
            url = f"{ELEVENLABS_API_URL}/{chosen_voice_id}"
            headers = {
                "xi-api-key": key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg",
            }
            payload = {
                "text": clean_text,
                "model_id": "eleven_multilingual_v2",
                "voice_settings": {
                    "stability": stability,
                    "similarity_boost": similarity_boost,
                    "style": 0.35,
                    "use_speaker_boost": True,
                },
            }

            try:
                response = requests.post(url, json=payload, headers=headers, timeout=12)
                if response.status_code == 200:
                    audio_bytes = response.content
                    if audio_bytes and len(audio_bytes) > 100:
                        self.store_audio_cache(audio_id, audio_bytes)
                        logger.info(f"ElevenLabs successfully synthesized {len(audio_bytes)} bytes for audio_id {audio_id[:8]}")
                        return audio_bytes, audio_id, "synthesized_elevenlabs"
                else:
                    logger.warning(f"ElevenLabs API error [{response.status_code}]: {response.text[:200]}")
            except requests.exceptions.RequestException as e:
                logger.warning(f"ElevenLabs connection failed: {e}")

        # 4. Fallback to local Neural TTS so audio playback NEVER fails
        fallback_bytes = self._synthesize_fallback(clean_text, audio_id)
        if fallback_bytes:
            return fallback_bytes, audio_id, "synthesized_fallback"

        return None, audio_id, "TTS synthesis unavailable"


# Singleton instance
elevenlabs_service = ElevenLabsService()
