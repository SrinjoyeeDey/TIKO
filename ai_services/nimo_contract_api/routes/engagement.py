"""
POST /analyze/engagement
Accepts a camera image frame and returns ENGAGEMENT_ANALYSIS event JSON.
Reports ONLY observations (face, gaze, mouth movement, score).
Never decides what NIMO should do — that is the backend's job.
"""
import io
import sys
import numpy as np
import cv2
from pathlib import Path
from datetime import datetime, timezone

# Add parent path to sys.path
pkg_dir = Path(__file__).resolve().parent.parent
if str(pkg_dir) not in sys.path:
    sys.path.insert(0, str(pkg_dir))

from fastapi import APIRouter, UploadFile, File, Form

try:
    from ai_services.nimo_contract_api.schemas import (
        EngagementAnalysisEvent, EngagementData
    )
except ImportError:
    try:
        from nimo_contract_api.schemas import (
            EngagementAnalysisEvent, EngagementData
        )
    except ImportError:
        from schemas import (
            EngagementAnalysisEvent, EngagementData
        )

router = APIRouter()


def _analyze_frame(frame_bytes: bytes) -> dict:
    """
    Analyze a single image frame using OpenCV for:
      - Face presence
      - Head gaze (approximate: face centered = looking at screen)
      - Mouth movement (open/closed ratio)
      - Engagement score 0–100
    Returns observation dict.  Does NOT make decisions.
    """
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if frame is None:
        return {
            "faceDetected":    False,
            "lookingAtScreen": False,
            "mouthMovement":   False,
            "engagementScore": 0
        }

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    h, w = frame.shape[:2]

    # --- Face Detection ---
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(60, 60))

    face_detected    = len(faces) > 0
    looking_at_screen = False
    mouth_movement   = False
    engagement_score = 0

    if face_detected:
        x, y, fw, fh = faces[0]
        face_cx = x + fw / 2
        face_cy = y + fh / 2

        # Gaze heuristic: face center within middle 60% of frame
        in_x = (w * 0.2) < face_cx < (w * 0.8)
        in_y = (h * 0.15) < face_cy < (h * 0.85)
        looking_at_screen = bool(in_x and in_y)

        # Mouth movement heuristic: lower face ROI brightness variance
        face_roi   = gray[y + int(fh * 0.6): y + fh, x: x + fw]
        mouth_var  = float(cv2.Laplacian(face_roi, cv2.CV_64F).var()) if face_roi.size > 0 else 0.0
        mouth_movement = mouth_var > 15.0

        # Engagement score (0–100) — weighted observation
        base = 50 if face_detected else 0
        gaze_bonus   = 30 if looking_at_screen else 0
        mouth_bonus  = 20 if mouth_movement else 0
        engagement_score = min(base + gaze_bonus + mouth_bonus, 100)

    return {
        "faceDetected":    face_detected,
        "lookingAtScreen": looking_at_screen,
        "mouthMovement":   mouth_movement,
        "engagementScore": engagement_score
    }


@router.post("/engagement", response_model=EngagementAnalysisEvent)
async def analyze_engagement(
    file:       UploadFile = File(...),
    childId:    str = Form("A001"),
    sessionId:  str = Form("SES_001"),
    activityId: str = Form("netaji_voice_01")
):
    """
    Analyzes uploaded image frame and returns a standardized ENGAGEMENT_ANALYSIS event.
    Only reports observations — does NOT recommend any actions.
    """
    frame_bytes = await file.read()
    obs = _analyze_frame(frame_bytes)

    data = EngagementData(**obs)

    return EngagementAnalysisEvent(
        source     = "python_vision",
        eventType  = "ENGAGEMENT_ANALYSIS",
        childId    = childId,
        sessionId  = sessionId,
        activityId = activityId,
        timestamp  = datetime.now(timezone.utc).isoformat(),
        data       = data
    )
