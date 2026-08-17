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


PEDIATRIC_DIFFICULTY_SYSTEM_PROMPT = """You are Dr. Nimo, an expert Pediatric Cognitive Psychologist and Educational Curriculum AI Specialist for early childhood education (ages 3 to 12).

Your task is to analyze a child's profile (Age, Grade/Standard, Native Language, and Learning Pace) and compute a single tailored Quest Difficulty Percentage (integer between 10 and 95).

### Pedagogical Benchmark Rules:
1. **Age <= 4 or Preschool / Nursery / LKG**:
   - Return Difficulty Percentage = 20 to 30.
2. **Age 5**:
   - 5-year-old in Nursery / LKG: Return Difficulty Percentage = 30.
   - 5-year-old in UKG: Return Difficulty Percentage = 40.
   - 5-year-old in Grade 1: Return Difficulty Percentage = 50.
3. **Age 6**:
   - 6-year-old in Grade 1: Return Difficulty Percentage = 50 to 55.
   - 6-year-old in Grade 2: Return Difficulty Percentage = 60.
4. **Age 7**:
   - 7-year-old in Grade 2: Return Difficulty Percentage = 60 to 65.
5. **Age 8 to 9**:
   - Grade 3 or 4: Return Difficulty Percentage = 70 to 80.
6. **Age 10 to 12**:
   - Grade 5+: Return Difficulty Percentage = 85 to 95.

### Pace Modifiers:
- Learning Pace = 'gentle': decrease by 5 to 8.
- Learning Pace = 'fast': increase by 5 to 8.

You must provide a structured output with the exact integer `difficultyPercentage`, `difficultyLevel` label, and brief `reasoning`."""


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
    Pedagogical heuristic fallback calculator when Groq API key is not configured or network fails.
    """
    age = req.age
    standard = (req.standard or "").strip().lower()
    pace = (req.learningPace or "normal").strip().lower()

    if age <= 4:
        base_pct = 25
        level = "Gentle Starter"
        reason = f"Ideal gentle starter quest calibrated for {age}-year-olds in early foundation stages."
    elif age == 5:
        if "lkg" in standard or "nursery" in standard or "preschool" in standard:
            base_pct = 30
            level = "Gentle Starter"
            reason = "Calibrated 30% difficulty for a 5-year-old in introductory standard."
        elif "ukg" in standard or "kindergarten" in standard:
            base_pct = 40
            level = "Balanced Explorer"
            reason = "Balanced 40% difficulty for a 5-year-old in UKG."
        elif "grade 1" in standard or "class 1" in standard or "1" in standard:
            base_pct = 50
            level = "Curious Adventurer"
            reason = "Tailored 50% difficulty for an active 5-year-old in Grade 1."
        else:
            base_pct = 35
            level = "Balanced Explorer"
            reason = "Personalized 35% quest difficulty designed for age 5 learners."
    elif age == 6:
        base_pct = 60 if ("grade 2" in standard or "class 2" in standard) else 50
        level = "Curious Adventurer"
        reason = f"Optimal {base_pct}% baseline difficulty for a 6-year-old."
    elif age == 7:
        base_pct = 65
        level = "Curious Adventurer"
        reason = "Engaging 65% difficulty supporting Grade 2 curriculum milestones."
    elif age in (8, 9):
        base_pct = 75
        level = "Challenger"
        reason = "Dynamic 75% challenge fostering deep comprehension and rapid memory recall."
    else:  # age >= 10
        base_pct = 85
        level = "Champion"
        reason = "Comprehensive 85% difficulty designed for independent learning."

    if pace == "gentle":
        base_pct = max(15, base_pct - 8)
    elif pace == "fast":
        base_pct = min(95, base_pct + 8)

    return DifficultyOutput(
        difficultyPercentage=base_pct,
        difficultyLevel=level,
        reasoning=reason,
    )


def assess_child_difficulty(req: DifficultyRequest) -> Tuple[DifficultyOutput, str]:
    """
    Main entry point for assessing initial child difficulty on sign-up using LangChain and ChatGroq.
    Returns (DifficultyOutput, modelUsedName).
    """
    api_key = os.environ.get("GROQ_API_KEY", "").strip()

    if not api_key:
        return _calculate_fallback_difficulty(req), "heuristic-fallback"

    user_prompt = f"""Assess difficulty for learner:
- Child Name: {req.name}
- Age: {req.age}
- Standard / Class: {req.standard}
- Preferred Language: {req.language or 'en'}
- Learning Pace: {req.learningPace or 'normal'}
- Specific Interests: {req.interests or 'adventures, stories'}

Return the structured difficultyPercentage."""

    try:
        llm = ChatGroq(
            temperature=0.1,
            model_name="llama-3.1-8b-instant",
            groq_api_key=api_key,
            max_tokens=250,
        )

        structured_llm = llm.with_structured_output(DifficultyOutput)

        messages = [
            SystemMessage(content=PEDIATRIC_DIFFICULTY_SYSTEM_PROMPT),
            HumanMessage(content=user_prompt),
        ]

        raw_result = structured_llm.invoke(messages)

        if isinstance(raw_result, DifficultyOutput):
            result = raw_result
        elif isinstance(raw_result, dict):
            result = DifficultyOutput(**raw_result)
        else:
            result = DifficultyOutput(
                difficultyPercentage=int(getattr(raw_result, "difficultyPercentage", 50)),
                difficultyLevel=str(getattr(raw_result, "difficultyLevel", "Balanced Explorer")),
                reasoning=str(getattr(raw_result, "reasoning", "")),
            )

        return result, "groq/llama-3.1-8b-instant (LangChain Structured Output)"
    except Exception as e:
        logger.warning(f"LangChain Groq invocation error: {e}")
        fallback = _calculate_fallback_difficulty(req)
        fallback.reasoning = f"Calibrated quest difficulty for age {req.age} ({req.standard})."
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

Compute updated difficultyPercentage (10-95), difficultyLevel, clinical reasoning, and next session recommendations."""

    try:
        llm = ChatGroq(
            temperature=0.15,
            model_name="llama-3.1-8b-instant",
            groq_api_key=api_key,
            max_tokens=400,
        )

        structured_llm = llm.with_structured_output(AdaptiveDifficultyOutput)

        messages = [
            SystemMessage(content=ADAPTIVE_SESSION_SYSTEM_PROMPT),
            HumanMessage(content=user_prompt),
        ]

        raw_result = structured_llm.invoke(messages)

        if isinstance(raw_result, AdaptiveDifficultyOutput):
            result = raw_result
        elif isinstance(raw_result, dict):
            result = AdaptiveDifficultyOutput(**raw_result)
        else:
            result = AdaptiveDifficultyOutput(
                difficultyPercentage=int(getattr(raw_result, "difficultyPercentage", curr_diff)),
                difficultyLevel=str(getattr(raw_result, "difficultyLevel", "Balanced Explorer")),
                reasoning=str(getattr(raw_result, "reasoning", "Calibrated by Dr. Nimo")),
                recommendationsForNextSession=list(getattr(raw_result, "recommendationsForNextSession", [])),
            )

        return result, "groq/llama-3.1-8b-instant (LangChain Structured Output)"
    except Exception as e:
        logger.warning(f"LangChain Groq adaptive invocation error: {e}")
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
