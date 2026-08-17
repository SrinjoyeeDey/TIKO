"""
Voice Interaction & Dialogue Service
====================================
Generates dynamic, non-hallucinated child-facing dialogues grounded strictly
in runtime application state (discovered chapters, active question JSON,
child profiles, and completed level metrics), and synthesizes speech via ElevenLabs.
"""

import os
import base64
import logging
from pathlib import Path
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv

from langchain_groq import ChatGroq
from langchain_core.messages import SystemMessage, HumanMessage

from .elevenlabs_service import elevenlabs_service
from ..schemas import VoiceInteractionRequest, VoiceInteractionResponse

logger = logging.getLogger(__name__)

# Load environment
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


class VoiceInteractionService:
    """Orchestrates dynamic text dialogue generation and ElevenLabs speech synthesis."""

    def __init__(self):
        self.groq_api_key = os.environ.get("GROQ_API_KEY", "").strip()

    def _get_groq_llm(self) -> Optional[ChatGroq]:
        key = os.environ.get("GROQ_API_KEY", "").strip()
        if not key:
            return None
        try:
            return ChatGroq(
                temperature=0.3,
                model_name="llama-3.1-8b-instant",
                groq_api_key=key,
                max_tokens=200,
            )
        except Exception as e:
            logger.warning(f"Failed to initialize Groq LLM: {e}")
            return None

    @staticmethod
    def _extract_text_content(content: Any) -> str:
        """Safely extracts clean string text from LangChain message content."""
        if isinstance(content, str):
            raw = content
        elif isinstance(content, list):
            parts = []
            for item in content:
                if isinstance(item, str):
                    parts.append(item)
                elif isinstance(item, dict) and "text" in item:
                    parts.append(str(item["text"]))
                elif hasattr(item, "text"):
                    parts.append(str(item.text))
            raw = "".join(parts)
        elif content is None:
            raw = ""
        else:
            raw = str(content)
        return raw.strip().strip('"').strip("'")

    def process_interaction(
        self,
        req: VoiceInteractionRequest,
        base_url: str = "http://localhost:8001",
    ) -> VoiceInteractionResponse:
        """
        Handles any child-facing voice interaction based on interactionType.
        Strictly operates on provided application data without hardcoding or hallucinations.
        """
        interaction_type = req.interactionType.upper().strip()
        spoken_text = ""
        model_used = "Heuristic-Grounded"

        # ── 1. Post-Signup Introduction ──────────────────────────────────────
        if interaction_type in ("POST_SIGNUP_INTRO", "INTRO"):
            spoken_text, model_used = self._generate_post_signup_intro(req)

        # ── 2. Question Section Voice Reader ─────────────────────────────────
        elif interaction_type in ("READ_QUESTION", "QUESTION"):
            spoken_text, model_used = self._generate_question_speech(req)

        # ── 3. Pronunciation Guide Section ───────────────────────────────────
        elif interaction_type in ("PRONOUNCE_PHRASE", "PRONUNCIATION"):
            spoken_text, model_used = self._generate_pronunciation_speech(req)

        # ── 4. Retry Question Prompt ─────────────────────────────────────────
        elif interaction_type in ("RETRY_QUESTION", "RETRY"):
            spoken_text, model_used = self._generate_retry_speech(req)

        # ── 5. Level Completion Celebration ──────────────────────────────────
        elif interaction_type in ("LEVEL_COMPLETION", "CELEBRATION"):
            spoken_text, model_used = self._generate_level_celebration(req)

        # ── Fallback / Direct Text ───────────────────────────────────────────
        else:
            spoken_text = req.customText or req.questionText or req.targetPhrase or "Let's explore together!"
            model_used = "Direct Text"

        # Synthesize audio with ElevenLabs
        audio_bytes, audio_id, status = elevenlabs_service.synthesize(
            text=spoken_text,
            voice_id=req.voiceId,
        )

        audio_url = f"{base_url}/voice/audio/{audio_id}" if audio_id else None
        audio_b64 = base64.b64encode(audio_bytes).decode("utf-8") if (audio_bytes and len(audio_bytes) < 400000) else None

        return VoiceInteractionResponse(
            success=True,
            interactionType=interaction_type,
            spokenText=spoken_text,
            audioId=audio_id,
            audioUrl=audio_url,
            audioBase64=audio_b64,
            audioFormat="audio/mpeg",
            ttsStatus=status,
            modelUsed=f"{model_used} + ElevenLabs TTS" if audio_bytes else f"{model_used} (TTS: {status})",
        )

    def _generate_post_signup_intro(self, req: VoiceInteractionRequest) -> tuple[str, str]:
        """Generates dynamic welcome intro mentioning real discovered chapters and child's profile."""
        name = req.childName or "Explorer"
        age = req.childAge or 6
        level = req.difficultyLevel or "Balanced Explorer"
        chapters = req.availableChapters or []
        first_chapter = req.chapterName or (chapters[0] if chapters else "Historical Quests")

        # Heuristic fallback template
        if chapters:
            chapters_str = ", ".join(chapters[:3])
            fallback_text = (
                f"Hello {name}! Welcome to NIMO The Warrior! "
                f"Your adventure begins with {first_chapter}. Get ready to discover historical stories and solve exciting quests!"
            )
        else:
            fallback_text = (
                f"Hello {name}! Welcome to NIMO The Warrior! "
                f"Your learning journey is calibrated for {level}. Let's begin our interactive quest!"
            )

        llm = self._get_groq_llm()
        if not llm:
            return fallback_text, "Grounded Heuristic"

        prompt = f"""You are Nimo, an encouraging and friendly companion in a children's historical learning app.
A child named {name} (Age {age}) has completed sign-up with a calibrated level of '{level}'.
The real discovered chapters available in the app are: {', '.join(chapters) if chapters else first_chapter}.
The starting chapter is: {first_chapter}.

Generate a 2-sentence warm, exciting spoken welcome introducing the game to {name} and inviting them to start {first_chapter}.
Rules:
1. ONLY mention the actual provided child name ({name}) and chapters ({first_chapter}).
2. Do NOT invent fictional topics or hardcoded content.
3. Keep it cheerful, spoken-friendly, and under 35 words. Return ONLY the spoken text."""

        try:
            res = llm.invoke([
                SystemMessage(content="You are Nimo, a friendly voice companion for children. Return only the raw spoken message."),
                HumanMessage(content=prompt),
            ])
            text = self._extract_text_content(res.content)
            return (text if text else fallback_text), "Groq LLaMA-3.1"
        except Exception as e:
            logger.warning(f"Post-signup intro Groq error: {e}")
            return fallback_text, "Grounded Heuristic"

    def _generate_question_speech(self, req: VoiceInteractionRequest) -> tuple[str, str]:
        """Reads the exact question currently displayed to the child."""
        q_num = req.questionNumber or 1
        q_text = (req.questionText or "").strip()

        if not q_text:
            return f"Question {q_num}. Please look at the screen and choose your answer.", "Grounded Heuristic"

        # Clean markdown / symbols for natural speech
        clean_text = q_text.replace("*", "").replace("#", "").strip()

        # If options are provided and it's MCQ, optionally append options clearly
        options_text = ""
        if req.options and len(req.options) > 0 and len(req.options) <= 4:
            opts_list = [f"Option {k}: {v}" for k, v in req.options.items()] if isinstance(req.options, dict) else [str(o) for o in req.options]
            options_text = " " + ". ".join(opts_list)

        spoken = f"Question {q_num}. {clean_text}{options_text if options_text and len(options_text) < 120 else ''}"
        return spoken, "Exact Question Data"

    def _generate_pronunciation_speech(self, req: VoiceInteractionRequest) -> tuple[str, str]:
        """Pronounces the exact word/phrase provided by the game."""
        phrase = (req.targetPhrase or req.questionText or "").strip()
        if not phrase:
            return "Please speak clearly into the microphone.", "Grounded Heuristic"

        # For pronunciation, we want the AI to pronounce the exact phrase with clear articulation
        return phrase, "Exact Pronunciation Target"

    def _generate_retry_speech(self, req: VoiceInteractionRequest) -> tuple[str, str]:
        """Generates encouraging, state-aware retry prompt with active question/word."""
        target = (req.targetPhrase or "").strip()
        q_text = (req.questionText or "").strip()
        retry_num = req.retryCount or 1

        if target:
            if retry_num > 1:
                spoken = f"Let's try one more time! Listen carefully and repeat: {target}"
            else:
                spoken = f"Nice try! Listen carefully and say: {target}"
        elif q_text:
            spoken = f"Let's try again! {q_text}"
        else:
            spoken = "You can do it! Give it another try!"

        return spoken, "State-Aware Retry Handler"

    def _generate_level_celebration(self, req: VoiceInteractionRequest) -> tuple[str, str]:
        """Generates dynamic celebration strictly based on the completed level and game state."""
        name = req.childName or "Warrior"
        level_name = req.levelName or "the level"
        chapter_name = req.chapterName or "the story"
        stars = req.stars if req.stars is not None else 3
        correct = req.totalCorrect if req.totalCorrect is not None else 0
        total = req.totalQuestions if req.totalQuestions is not None else 0

        # Heuristic fallback
        if stars == 3:
            star_phrase = "a perfect 3 stars!"
        elif stars == 2:
            star_phrase = "2 shining stars!"
        elif stars == 1:
            star_phrase = "a victory star!"
        else:
            star_phrase = "great effort!"

        fallback = f"Hooray {name}! You successfully completed {level_name} with {star_phrase} Wonderful job on {chapter_name}!"

        llm = self._get_groq_llm()
        if not llm:
            return fallback, "Grounded Heuristic"

        prompt = f"""You are Nimo, an enthusiastic child learning companion.
A learner named {name} just completed {level_name} in {chapter_name}.
Actual results:
- Stars earned: {stars} out of 3
- Questions answered correctly: {correct} out of {total}

Generate a short, 1-2 sentence cheerful congratulatory message celebrating {name}'s exact achievement.
Rules:
1. Only state the real level name ({level_name}), chapter ({chapter_name}), and score ({stars} stars).
2. Do NOT invent unearned badges, scores, or achievements.
3. Keep it under 25 words. Return ONLY the spoken text."""

        try:
            res = llm.invoke([
                SystemMessage(content="You are Nimo, a friendly voice companion for children. Return only the raw spoken message."),
                HumanMessage(content=prompt),
            ])
            text = self._extract_text_content(res.content)
            return (text if text else fallback), "Groq LLaMA-3.1"
        except Exception as e:
            logger.warning(f"Level celebration Groq error: {e}")
            return fallback, "Grounded Heuristic"


# Singleton instance
voice_service = VoiceInteractionService()
