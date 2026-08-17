"""
NIMO Python Model Integration Contract API
==========================================
This module is a clean, self-contained FastAPI server that exposes the
standardized JSON contract endpoints required by the NIMO backend team.

Endpoints:
  POST /analyze/speech        - Analyzes audio and returns SPEECH_ANALYSIS event
  POST /analyze/engagement    - Analyzes image frame and returns ENGAGEMENT_ANALYSIS event
  POST /calculate/difficulty  - Groq LLM pediatric cognitive quest difficulty calculator
  POST /assess/difficulty     - Alias for difficulty calculation
  GET  /health                - Health check

All outputs strictly follow the NIMO Integration Contract format.
"""

import sys
from pathlib import Path

# Auto-configure sys.path so any invocation mode works seamlessly
_current_file = Path(__file__).resolve()
_nimo_contract_dir = _current_file.parent
_ai_services_dir = _nimo_contract_dir.parent
_workspace_root = _ai_services_dir.parent

for p in [str(_nimo_contract_dir), str(_ai_services_dir), str(_workspace_root)]:
    if p not in sys.path:
        sys.path.insert(0, p)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

try:
    from .routes import engagement, speech, difficulty
except (ImportError, ValueError):
    try:
        from nimo_contract_api.routes import engagement, speech, difficulty
    except (ImportError, ValueError):
        from routes import engagement, speech, difficulty

app = FastAPI(
    title="NIMO Python Model API",
    description="Standardized observation outputs for Speech, Engagement, and Groq LLM Difficulty Assessment.",
    version="1.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(speech.router,     prefix="/analyze",   tags=["Speech"])
app.include_router(engagement.router, prefix="/analyze",   tags=["Engagement"])
app.include_router(difficulty.router, prefix="/calculate", tags=["Difficulty"])
app.include_router(difficulty.router, prefix="/assess",    tags=["Difficulty"])

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "NIMO Python Model Contract API",
        "models": ["speech", "vision", "groq_difficulty"]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
