"""
NIMO Python Model Integration Contract API
==========================================
This module is a clean, self-contained FastAPI server that exposes the
standardized JSON contract endpoints required by the NIMO backend team.

Endpoints:
  POST /analyze/speech      - Analyzes audio and returns SPEECH_ANALYSIS event
  POST /analyze/engagement  - Analyzes image frame and returns ENGAGEMENT_ANALYSIS event
  GET  /health              - Health check

All outputs strictly follow the NIMO Integration Contract format.
"""

import sys
from pathlib import Path

# Add project root and ai_services directory to sys.path
root_dir = Path(__file__).resolve().parent.parent.parent
ai_dir = Path(__file__).resolve().parent.parent
pkg_dir = Path(__file__).resolve().parent

for p in [str(root_dir), str(ai_dir), str(pkg_dir)]:
    if p not in sys.path:
        sys.path.insert(0, p)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

try:
    from .routes import speech, engagement  # type: ignore
except (ImportError, ValueError):
    try:
        from ai_services.nimo_contract_api.routes import speech, engagement  # type: ignore
    except ImportError:
        try:
            from nimo_contract_api.routes import speech, engagement  # type: ignore
        except ImportError:
            from routes import speech, engagement  # type: ignore

app = FastAPI(
    title="NIMO Python Model API",
    description="Standardized observation outputs for Speech and Engagement analysis.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(speech.router,     prefix="/analyze", tags=["Speech"])
app.include_router(engagement.router, prefix="/analyze", tags=["Engagement"])

@app.get("/health")
def health():
    return {"status": "ok", "service": "NIMO Python Model Contract API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
