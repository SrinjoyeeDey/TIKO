"""
POST /calculate/difficulty
POST /calculate/adaptive-difficulty
Accepts child profile parameters and post-level clinical metrics
(current ability, previous performance, preferred interaction, speech ability,
motor performance, attention pattern, and learning history)
and returns an LLM-calculated structured difficulty percentage (0-100%) for SQLite storage.
"""

from fastapi import APIRouter
from ..schemas import (
    DifficultyRequest,
    DifficultyResponse,
    AdaptiveSessionEvaluationRequest,
    AdaptiveDifficultyResponse,
)
from ..services.groq_difficulty_service import (
    assess_child_difficulty,
    assess_adaptive_session_difficulty,
)

router = APIRouter()


@router.post("/difficulty", response_model=DifficultyResponse)
async def calculate_difficulty(req: DifficultyRequest):
    """
    Computes initial personalized quest difficulty percentage using Groq LLM
    via LangChain Structured Output (with_structured_output).
    Returns pure integer difficultyPercentage for SQLite persistence.
    """
    diff_output, model_name = assess_child_difficulty(req)

    return DifficultyResponse(
        success=True,
        childId=req.childId or "child_001",
        difficultyPercentage=diff_output.difficultyPercentage,
        difficultyLevel=diff_output.difficultyLevel or "Balanced Explorer",
        reasoning=diff_output.reasoning or "",
        modelUsed=model_name,
    )


@router.post("/adaptive-difficulty", response_model=AdaptiveDifficultyResponse)
@router.post("/adaptive", response_model=AdaptiveDifficultyResponse)
async def calculate_adaptive_difficulty(req: AdaptiveSessionEvaluationRequest):
    """
    Evaluates completed level clinical telemetry (current ability, previous performance,
    preferred interaction, speech ability, motor performance, attention pattern, and learning history)
    using Groq LLM to calculate the updated difficulty percentage for the next session.
    """
    output, model_name = assess_adaptive_session_difficulty(req)

    return AdaptiveDifficultyResponse(
        success=True,
        childId=req.childId,
        difficultyPercentage=output.difficultyPercentage,
        difficultyLevel=output.difficultyLevel or "Balanced Explorer",
        reasoning=output.reasoning or "",
        recommendationsForNextSession=output.recommendationsForNextSession or [],
        modelUsed=model_name,
    )
