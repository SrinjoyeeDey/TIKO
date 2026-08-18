"""
Modular Groq & LangChain Difficulty Assessment Service
======================================================
Analyzes a child learner's profile (Age, Standard/Grade, Language, Learning Pace)
as well as Post-Level Clinical Telemetry (Current Ability, Previous Performance,
Preferred Interaction, Speech Ability, Motor Performance, Attention Pattern,
and Learning History) using Groq LLM (LLaMA-3.1-8B-Instant) with LangChain
Structured Output (`with_structured_output`) to calculate the adaptive difficulty level
for the next session.

Environment:
  GROQ_API_KEY can be provided in:
    - `ai_services/.env`
    - root `.env`
    - System environment variables
"""

import os
import json
import logging
from pathlib import Path
from typing import Tuple
from dotenv import load_dotenv

from groq import Groq
from langchain_groq import ChatGroq
from langchain_core.messages import SystemMessage, HumanMessage

from ..schemas import (
    DifficultyRequest,
    DifficultyOutput,
    AdaptiveSessionEvaluationRequest,
    AdaptiveDifficultyOutput,
)

logger = logging.getLogger(__name__)

# Load environment variables from ai_services/.env or root .env
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


PEDIATRIC_DIFFICULTY_SYSTEM_PROMPT = """You are Dr. Nimo, an expert Pediatric Cognitive Psychologist, Speech-Language Pathologist, and Adaptive Curriculum AI Specialist for early childhood education (ages 3 to 12).

Your task is to analyze a child's complete profile—combining their Age, Grade/Standard, and particularly their 15-Question Onboarding Pediatric Assessment—to calculate an individualized Quest Difficulty Percentage (integer between 10 and 95) and difficulty level.

### Clinical Assessment Calibration Dimensions:
1. **Age & Standard Baseline**:
   - Age 3-4 (Nursery/Preschool): Base 25%
   - Age 5 (UKG/Grade 1): Base 35% - 50%
   - Age 6 (Grade 1/2): Base 50% - 60%
   - Age 7 (Grade 2): Base 60% - 65%
   - Age 8-9 (Grade 3/4): Base 70% - 80%
   - Age 10-12 (Grade 5+): Base 85% - 95%

2. **15-Question Onboarding Evaluation Modifiers**:
   - **Speech & Expressive Language**: If child speaks in single words/gestures or has Apraxia/Speech Delay: adjust difficulty downwards (-10% to -20%) to provide supportive phonetic scaffolding. If child speaks in full fluent sentences: adjust upwards (+5% to +10%).
   - **Receptive Comprehension & Concept Understanding**: If child needs one-step instructions or struggles with sequence ("first/next/last") or time words: adjust difficulty downwards (-5% to -12%) for structured bite-sized tasks. If child easily follows multi-step instructions: adjust upwards (+5%).
   - **Attention Span & Engagement**: If attention is 3-5 min bursts or easily distracted: calibrate for bite-sized micro-sessions with engaging feedback (-5%). If 10+ min sustained focus: maintain standard or higher pacing (+5%).
   - **Emotional Regulation & Frustration**: If child gets easily upset/needs breaks: lower difficulty (-5% to -10%) to build confidence and avoid cognitive overload.
   - **Parent Self-Rated Speech Baseline Slider (0.0 to 1.0)**:
     * 0.00 - 0.33 ("Getting started"): Cap maximum difficulty to 35% (Gentle Starter).
     * 0.34 - 0.66 ("Great progress"): Target 40% - 65% (Balanced Explorer to Curious Adventurer).
     * 0.67 - 1.00 ("Excellent"): Target 65% - 90% (Challenger to Champion).
   - **Developmental Diagnoses (ASD, ADHD, Apraxia, Speech Delay)**: Apply compassionate neurodiverse scaffolding, emphasizing clear visual cues and relaxed pacing.

### Difficulty Levels:
- **Gentle Starter** (10 - 35%): Maximum supportive scaffolding, single-step prompts, audio repetition.
- **Balanced Explorer** (36 - 50%): Balanced multisensory pacing, standard vocabulary, visual hints.
- **Curious Adventurer** (51 - 65%): Multi-step instructions, standard questions, moderate complexity.
- **Challenger** (66 - 80%): Advanced phonic recognition, sequential logic, minimal hints.
- **Champion** (81 - 95%): Deep comprehension, complex multi-part questions, rapid recall.

You must return strictly valid JSON formatted as a JSON object:
{
  "difficultyPercentage": <integer between 10 and 95>,
  "difficultyLevel": "<Gentle Starter | Balanced Explorer | Curious Adventurer | Challenger | Champion>",
  "reasoning": "<concise 1-2 sentence clinical summary referencing key factors from their 15 onboarding questions>"
}"""


ADAPTIVE_SESSION_SYSTEM_PROMPT = """You are Dr. Nimo, a Senior Pediatric Cognitive Psychologist and Adaptive Curriculum AI Specialist.

You have received comprehensive post-level clinical and cognitive metrics for a child's completed story session:
1. Current Ability: Overall comprehension and mastery score
2. Previous Performance: Stars achieved, accuracy rate, score consistency
3. Preferred Interaction: Visual, verbal, and sensory engagement preferences
4. Speech Ability: Verbal vocalization count, pronunciation fidelity %, articulation response latency
5. Motor Performance: Touch accuracy, drag-and-drop narrative sequencing fidelity
6. Attention Pattern: Screen gaze stability %, distraction occurrences, focus lock
7. Learning History: Activities completed, hints requested, frustration resistance / retries

### Adaptive Difficulty Progression Principles:
- **Outstanding Mastery** (>85% accuracy, >75% speech, >80% gaze, 0 hints):
  -> Advance difficulty by +5% to +10% (max 95%).
- **Steady Explorer** (65% - 80% accuracy, stable attention):
  -> Moderate increase or maintain (±2% to +5%).
- **Developing / Struggling** (<60% accuracy, >=3 hints, lower speech/sequencing):
  -> Gently reduce difficulty by -5% to -10% (min 15%) to maintain motivation and build foundational concepts.
- **Frustration Indicated** (multiple rapid retries, high grip pressure):
  -> Reduce difficulty by -8% to -12% with supportive scaffolding recommendations.

Return a structured JSON with:
- `difficultyPercentage`: integer between 10 and 95
- `difficultyLevel`: "Gentle Starter" (<=35), "Balanced Explorer" (36-50), "Curious Adventurer" (51-65), "Challenger" (66-80), or "Champion" (>80)
- `reasoning`: Concise 1-2 sentence clinical summary of why this difficulty was calibrated.
- `recommendationsForNextSession`: 2 to 3 actionable suggestions for the next chapter."""


def _calculate_fallback_difficulty(req: DifficultyRequest) -> DifficultyOutput:
    """
    Pedagogical heuristic fallback calculator synthesizing the 15 onboarding questions,
    diagnoses, and speech level slider when Groq API is offline.
    """
    age = req.age
    standard = (req.standard or "").strip().lower()
    pace = (req.learningPace or "normal").strip().lower()

    if age <= 4:
        base_pct = 25
    elif age == 5:
        if "lkg" in standard or "nursery" in standard or "preschool" in standard:
            base_pct = 30
        elif "ukg" in standard or "kindergarten" in standard:
            base_pct = 40
        elif "grade 1" in standard or "class 1" in standard or "1" in standard:
            base_pct = 50
        else:
            base_pct = 35
    elif age == 6:
        base_pct = 60 if ("grade 2" in standard or "class 2" in standard) else 50
    elif age == 7:
        base_pct = 65
    elif age in (8, 9):
        base_pct = 75
    else:  # age >= 10
        base_pct = 85

    # Modifiers from 15-Question Onboarding Assessment Answers
    answers = req.onboardingAnswers or {}
    diagnoses = req.diagnoses or []

    # 1. Diagnoses modifier
    has_delay = any(d in ["Speech & Language Delay", "Childhood Apraxia of Speech", "Developmental Delay"] for d in diagnoses)
    if has_delay:
        base_pct -= 10

    # 2. Receptive comprehension modifier
    for q_text, ans in answers.items():
        ans_str = str(ans).lower()
        if "instruction" in q_text.lower():
            if "one step" in ans_str:
                base_pct -= 8
            elif "easily" in ans_str:
                base_pct += 5
        elif "express" in q_text.lower() or "speaking" in q_text.lower() or "sentences" in q_text.lower():
            if "gestures" in ans_str or "single words" in ans_str:
                base_pct -= 10
            elif "full sentences" in ans_str:
                base_pct += 5
        elif "frustrat" in q_text.lower() or "react" in q_text.lower():
            if "upset" in ans_str or "break" in ans_str:
                base_pct -= 6

    # 3. Speech Level Slider modifier
    if req.speechLevelSlider is not None:
        if req.speechLevelSlider <= 0.33:
            base_pct = min(base_pct, 35)
        elif req.speechLevelSlider >= 0.70:
            base_pct = max(base_pct, 65)

    if pace == "gentle":
        base_pct -= 5
    elif pace == "fast":
        base_pct += 5

    base_pct = max(15, min(95, base_pct))

    if base_pct <= 35:
        level = "Gentle Starter"
        reason = f"Calibrated {base_pct}% gentle starter quest with supportive pacing based on 15-question developmental assessment."
    elif base_pct <= 50:
        level = "Balanced Explorer"
        reason = f"Calibrated {base_pct}% balanced explorer difficulty tailored from 15-question cognitive baseline."
    elif base_pct <= 65:
        level = "Curious Adventurer"
        reason = f"Calibrated {base_pct}% curious adventurer challenge fostering multi-step comprehension and articulation."
    elif base_pct <= 80:
        level = "Challenger"
        reason = f"Calibrated {base_pct}% challenger level supporting rapid recall and sequential reasoning."
    else:
        level = "Champion"
        reason = f"Calibrated {base_pct}% champion level designed for comprehensive independent mastery."

    return DifficultyOutput(
        difficultyPercentage=base_pct,
        difficultyLevel=level,
        reasoning=reason,
    )


import re

GROQ_MODEL_CANDIDATES = [
    "openai/gpt-oss-20b",
    "openai/gpt-oss-120b",
    "qwen/qwen3.6-27b",
    "allam-2-7b",
]


def _extract_json(text: str) -> dict:
    """Safely extracts and parses JSON dictionary from LLM output with regex fallbacks."""
    if not text:
        return {}

    # 1. Clean markdown code fences if present
    cleaned = re.sub(r"^```(?:json)?", "", text.strip(), flags=re.MULTILINE)
    cleaned = re.sub(r"```$", "", cleaned.strip(), flags=re.MULTILINE).strip()

    try:
        return json.loads(cleaned)
    except Exception:
        pass

    # 2. Try regex extraction of first complete { ... }
    match = re.search(r"\{[\s\S]*\}", cleaned)
    if match:
        try:
            return json.loads(match.group(0))
        except Exception:
            pass

    # 3. Robust partial regex extraction for individual fields
    data = {}
    pct_match = re.search(r'"difficultyPercentage"\s*:\s*(\d+)', text)
    if pct_match:
        data["difficultyPercentage"] = int(pct_match.group(1))

    level_match = re.search(r'"difficultyLevel"\s*:\s*"([^"]+)"', text)
    if level_match:
        data["difficultyLevel"] = level_match.group(1)

    reasoning_match = re.search(r'"reasoning"\s*:\s*"([^"]+)"', text)
    if reasoning_match:
        data["reasoning"] = reasoning_match.group(1)

    return data


def assess_child_difficulty(req: DifficultyRequest) -> Tuple[DifficultyOutput, str]:
    """
    Main entry point for assessing initial child difficulty on sign-up using LangChain and ChatGroq.
    Deeply synthesizes 15 onboarding questions, parent speech slider, and developmental profile.
    Returns (DifficultyOutput, modelUsedName).
    """
    api_key = os.environ.get("GROQ_API_KEY", "").strip()

    if not api_key:
        return _calculate_fallback_difficulty(req), "heuristic-fallback"

    # Format onboarding assessment details
    onboarding_summary = ""
    if req.diagnoses:
        onboarding_summary += f"\n- Diagnoses / Developmental Flags: {', '.join(req.diagnoses)}"
    if req.speechLevelSlider is not None:
        slider_rating = "Getting Started" if req.speechLevelSlider <= 0.33 else ("Great Progress" if req.speechLevelSlider <= 0.66 else "Excellent")
        onboarding_summary += f"\n- Parent Self-Rated Speech Level: {slider_rating} ({req.speechLevelSlider:.2f})"
    if req.onboardingAnswers:
        onboarding_summary += "\n- 15-Question Onboarding Pediatric Assessment Responses:"
        for q, a in req.onboardingAnswers.items():
            onboarding_summary += f"\n  * {q}: {a}"

    user_prompt = f"""Assess initial personalized quest difficulty for learner based on child profile and sign-up onboarding assessment:
- Child Name: {req.name}
- Age: {req.age}
- Standard / Class: {req.standard}
- Preferred Language: {req.language or 'en'}
- Learning Pace: {req.learningPace or 'normal'}
- Specific Interests: {req.interests or 'adventures, stories'}{onboarding_summary}

Synthesize the 15 onboarding answers, diagnoses, and baseline slider to compute the tailored difficulty percentage (10 to 95), difficultyLevel label, and clinical reasoning."""

    client = Groq(api_key=api_key)

    for model_name in GROQ_MODEL_CANDIDATES:
        try:
            chat_completion = client.chat.completions.create(
                model=model_name,
                messages=[
                    {"role": "system", "content": PEDIATRIC_DIFFICULTY_SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.1,
                max_tokens=800,
            )

            raw_text = chat_completion.choices[0].message.content or ""
            data = _extract_json(raw_text)

            if not data or "difficultyPercentage" not in data:
                continue

            diff_pct = int(data.get("difficultyPercentage", 50))
            diff_pct = max(10, min(95, diff_pct))
            diff_level = str(data.get("difficultyLevel", "Balanced Explorer"))
            reasoning = str(data.get("reasoning", "Calibrated by Groq Pediatric AI Engine based on 15 onboarding questions."))

            logger.info(f"Groq difficulty assessment succeeded with {model_name}: {diff_pct}% ({diff_level})")
            return DifficultyOutput(
                difficultyPercentage=diff_pct,
                difficultyLevel=diff_level,
                reasoning=reasoning,
            ), f"groq/{model_name}"
        except Exception as e:
            logger.warning(f"Groq invocation error with model {model_name}: {e}")
            continue

    fallback = _calculate_fallback_difficulty(req)
    return fallback, "heuristic-fallback"


def assess_adaptive_session_difficulty(
    req: AdaptiveSessionEvaluationRequest,
) -> Tuple[AdaptiveDifficultyOutput, str]:
    """
    Evaluates completed level telemetry across 7 clinical dimensions to calculate
    the updated adaptive quest difficulty for the next session.
    """
    api_key = os.environ.get("GROQ_API_KEY", "").strip()

    # Heuristic baseline calculation
    curr_diff = req.currentDifficultyPercentage or 50

    if not api_key:
        return _calculate_adaptive_fallback(req, curr_diff), "heuristic-fallback"

    user_prompt = f"""Evaluate completed level clinical telemetry for next session difficulty adaptation:
- Child: {req.name}, Age: {req.age}, Standard: {req.standard}
- Current Difficulty Baseline: {curr_diff}%
- Current Ability: {req.currentAbility}
- Previous Performance: {req.previousPerformance}
- Preferred Interaction: {req.preferredInteraction}
- Speech Ability: {req.speechAbility}
- Motor Performance: {req.motorPerformance}
- Attention Pattern: {req.attentionPattern}
- Learning History: {req.learningHistory}

Return ONLY a JSON object with exact keys:
- difficultyPercentage: integer (10 to 95)
- difficultyLevel: string ("Gentle Starter", "Balanced Explorer", "Curious Adventurer", "Challenger", "Champion")
- reasoning: string
- recommendationsForNextSession: list of 2-3 strings"""

    client = Groq(api_key=api_key)

    for model_name in GROQ_MODEL_CANDIDATES:
        try:
            chat_completion = client.chat.completions.create(
                model=model_name,
                messages=[
                    {"role": "system", "content": ADAPTIVE_SESSION_SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.15,
                max_tokens=800,
            )

            raw_text = chat_completion.choices[0].message.content or ""
            data = _extract_json(raw_text)

            if not data or "difficultyPercentage" not in data:
                continue

            diff_pct = int(data.get("difficultyPercentage", curr_diff))
            diff_pct = max(10, min(95, diff_pct))
            diff_level = str(data.get("difficultyLevel", "Balanced Explorer"))
            reasoning = str(data.get("reasoning", "Calibrated by Dr. Nimo AI"))
            recs = data.get("recommendationsForNextSession", [])
            if not isinstance(recs, list):
                recs = [str(recs)]

            return AdaptiveDifficultyOutput(
                difficultyPercentage=diff_pct,
                difficultyLevel=diff_level,
                reasoning=reasoning,
                recommendationsForNextSession=[str(r) for r in recs],
            ), f"groq/{model_name}"
        except Exception as e:
            logger.warning(f"Groq adaptive invocation error with {model_name}: {e}")
            continue

    return _calculate_adaptive_fallback(req, curr_diff), "heuristic-fallback"


def _calculate_adaptive_fallback(
    req: AdaptiveSessionEvaluationRequest,
    current_pct: int,
) -> AdaptiveDifficultyOutput:
    """Heuristic adaptive fallback algorithm."""
    pct = current_pct
    reasoning_parts = []

    # Check performance keywords
    perf_str = (req.previousPerformance or "").lower()
    speech_str = (req.speechAbility or "").lower()
    attention_str = (req.attentionPattern or "").lower()
    motor_str = (req.motorPerformance or "").lower()
    history_str = (req.learningHistory or "").lower()

    if "100%" in perf_str or "3 stars" in perf_str:
        pct += 5
        reasoning_parts.append("Perfect score demonstrated strong mastery")
    elif "struggled" in perf_str or "0 stars" in perf_str or "1 star" in perf_str:
        pct -= 5
        reasoning_parts.append("Level challenge adjusted to reinforce foundational concepts")

    if "high" in attention_str or "90%" in attention_str or "gaze lock" in attention_str:
        pct += 2
        reasoning_parts.append("outstanding visual attention & screen focus")

    if "retries" in motor_str or "hints" in history_str:
        if "3 hints" in history_str or "4 hints" in history_str:
            pct -= 5
            reasoning_parts.append("multi-step hints requested")

    pct = max(15, min(95, pct))

    if pct <= 35:
        level = "Gentle Starter"
    elif pct <= 50:
        level = "Balanced Explorer"
    elif pct <= 65:
        level = "Curious Adventurer"
    elif pct <= 80:
        level = "Challenger"
    else:
        level = "Champion"

    reason = "Dr. Nimo adaptive calibration: " + (", ".join(reasoning_parts) if reasoning_parts else "Progressing at a healthy personalized pace.")

    return AdaptiveDifficultyOutput(
        difficultyPercentage=pct,
        difficultyLevel=level,
        reasoning=reason,
        recommendationsForNextSession=[
            "Continue story exploration with visual and audio guidance.",
            "Practice narrative sequencing cards at home.",
        ],
    )
