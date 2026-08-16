"""
POST /analyze/engagement
Accepts a camera image frame and returns ENGAGEMENT_ANALYSIS event JSON.
Reports ONLY observations (face, gaze, mouth movement, score).
Uses CLAHE lighting equalization, multi-cascade ensemble face detection,
geometric gaze alignment, and temporal mouth motion tracking.
"""
from importlib import import_module
from pathlib import Path
from datetime import datetime, timezone
import math
from typing import Any, Dict, List, Tuple

import numpy as np
from fastapi import APIRouter, UploadFile, File, Form

from ..schemas import EngagementAnalysisEvent, EngagementData

try:
    cv2: Any = import_module("cv2")
except ModuleNotFoundError:
    cv2 = None

router = APIRouter()

# Cascade filenames
_CASCADE_ALT2 = "haarcascade_frontalface_alt2.xml"
_CASCADE_ALT = "haarcascade_frontalface_alt.xml"
_CASCADE_DEFAULT = "haarcascade_frontalface_default.xml"
_CASCADE_PROFILE = "haarcascade_profileface.xml"
_CASCADE_EYE_TREE = "haarcascade_eye_tree_eyeglasses.xml"
_CASCADE_EYE = "haarcascade_eye.xml"
_CASCADE_SMILE = "haarcascade_smile.xml"


def _load_cascade(filename: str) -> Any | None:
    if cv2 is None or not hasattr(cv2, "data"):
        return None
    cascade_path = Path(cv2.data.haarcascades) / filename
    if not cascade_path.exists():
        return None
    try:
        classifier = cv2.CascadeClassifier(str(cascade_path))
        return None if classifier.empty() else classifier
    except Exception:
        return None


FACE_CASCADE_ALT2 = _load_cascade(_CASCADE_ALT2)
FACE_CASCADE_ALT = _load_cascade(_CASCADE_ALT)
FACE_CASCADE_DEFAULT = _load_cascade(_CASCADE_DEFAULT)
PROFILE_CASCADE = _load_cascade(_CASCADE_PROFILE)
EYE_CASCADE_TREE = _load_cascade(_CASCADE_EYE_TREE)
EYE_CASCADE = _load_cascade(_CASCADE_EYE) or EYE_CASCADE_TREE
SMILE_CASCADE = _load_cascade(_CASCADE_SMILE)


def _ensure_cascades() -> None:
    global FACE_CASCADE_ALT2, FACE_CASCADE_ALT, FACE_CASCADE_DEFAULT, PROFILE_CASCADE, EYE_CASCADE, SMILE_CASCADE
    if FACE_CASCADE_DEFAULT is None or FACE_CASCADE_ALT2 is None:
        FACE_CASCADE_ALT2 = _load_cascade(_CASCADE_ALT2)
        FACE_CASCADE_ALT = _load_cascade(_CASCADE_ALT)
        FACE_CASCADE_DEFAULT = _load_cascade(_CASCADE_DEFAULT)
        PROFILE_CASCADE = _load_cascade(_CASCADE_PROFILE)
        eye_tree = _load_cascade(_CASCADE_EYE_TREE)
        EYE_CASCADE = _load_cascade(_CASCADE_EYE) or eye_tree
        SMILE_CASCADE = _load_cascade(_CASCADE_SMILE)


# Running state buffers per session
_SESSION_SMOOTHED_SCORES: Dict[str, float] = {}
_SESSION_PREV_MOUTH_ROIS: Dict[str, np.ndarray] = {}


def _detect_faces_on_gray(gray_img: np.ndarray) -> Tuple[Any, bool]:
    """Helper to detect faces with multi-tier cascades."""
    _ensure_cascades()
    faces: Any = ()
    is_profile = False

    # 1. Alt2 (Most accurate frontal)
    if FACE_CASCADE_ALT2 is not None:
        faces = FACE_CASCADE_ALT2.detectMultiScale(
            gray_img,
            scaleFactor=1.06,
            minNeighbors=3,
            minSize=(24, 24),
        )

    # 2. Alt (Ensemble fallback)
    if len(faces) == 0 and FACE_CASCADE_ALT is not None:
        faces = FACE_CASCADE_ALT.detectMultiScale(
            gray_img,
            scaleFactor=1.06,
            minNeighbors=3,
            minSize=(24, 24),
        )

    # 3. Default (Broad coverage)
    if len(faces) == 0 and FACE_CASCADE_DEFAULT is not None:
        faces = FACE_CASCADE_DEFAULT.detectMultiScale(
            gray_img,
            scaleFactor=1.08,
            minNeighbors=2,
            minSize=(20, 20),
        )

    # 4. Profile (Looking sideways/tilted)
    if len(faces) == 0 and PROFILE_CASCADE is not None:
        faces = PROFILE_CASCADE.detectMultiScale(
            gray_img,
            scaleFactor=1.08,
            minNeighbors=2,
            minSize=(20, 20),
        )
        if len(faces) > 0:
            is_profile = True

    return faces, is_profile


def _analyze_frame(frame_bytes: bytes, session_id: str = "default") -> dict:
    """
    Analyze a single image frame using OpenCV for:
      - CLAHE lighting-invariant face detection (Alt2 -> Alt -> Default -> Profile)
      - Continuous geometric Gaze Alignment calculation
      - Eye detection with eyeglasses-aware Haar cascade
      - Adaptive lip movement tracking via normalized difference & edge variance
      - Real-time smooth engagement scoring (0-100%)
    """
    if cv2 is None:
        return {
            "faceDetected": False,
            "lookingAtScreen": False,
            "mouthMovement": False,
            "engagementScore": 0,
        }

    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if frame is None or frame.size == 0:
        _SESSION_SMOOTHED_SCORES[session_id] = 0.0
        _SESSION_PREV_MOUTH_ROIS.pop(session_id, None)
        return {
            "faceDetected": False,
            "lookingAtScreen": False,
            "mouthMovement": False,
            "engagementScore": 0,
        }

    # Scale to optimal resolution (640px max) for high detection accuracy with <10ms CPU inference
    h, w = frame.shape[:2]
    max_dim = 640
    if max(h, w) > max_dim:
        scale = max_dim / float(max(h, w))
        small_frame = cv2.resize(frame, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
    else:
        small_frame = frame

    gray = cv2.cvtColor(small_frame, cv2.COLOR_BGR2GRAY)
    sw_h, sw_w = gray.shape[:2]

    # CLAHE (Contrast Limited Adaptive Histogram Equalization) for lighting invariance
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray_eq = clahe.apply(gray)

    # 1. Multi-tier Cascade Face Detection across lighting representations
    faces: Any = ()
    is_profile = False

    for test_img in (gray_eq, gray, cv2.equalizeHist(gray)):
        faces, is_profile = _detect_faces_on_gray(test_img)
        if len(faces) > 0:
            break

    face_detected = len(faces) > 0
    looking_at_screen = False
    mouth_movement = False
    raw_engagement_score = 0.0

    if face_detected:
        # Pick largest detected face
        faces_sorted = sorted(faces, key=lambda b: b[2] * b[3], reverse=True)
        x, y, fw, fh = faces_sorted[0]
        face_cx = x + fw / 2.0
        face_cy = y + fh / 2.0

        # Continuous Euclidean Alignment from Center of Camera Frame (0.0 center -> 1.0 edges)
        norm_dx = abs(face_cx - (sw_w / 2.0)) / (sw_w / 2.0)
        norm_dy = abs(face_cy - (sw_h / 2.0)) / (sw_h / 2.0)

        # Center Alignment score (1.0 = centered, 0.0 = extreme edge)
        center_proximity = max(0.0, 1.0 - math.sqrt((norm_dx * 0.9) ** 2 + (norm_dy * 0.7) ** 2))

        # Eye Detection & Gaze Verification
        eye_factor = 0.85
        eye_cascade_to_use = EYE_CASCADE_TREE or EYE_CASCADE
        if not is_profile and eye_cascade_to_use is not None:
            upper_face = gray_eq[y : y + int(fh * 0.55), x : x + fw]
            if upper_face.size > 0:
                eyes = eye_cascade_to_use.detectMultiScale(
                    upper_face,
                    scaleFactor=1.08,
                    minNeighbors=2,
                    minSize=(10, 10),
                )
                num_eyes = len(eyes)
                if num_eyes >= 2:
                    eye_factor = 1.0
                elif num_eyes == 1:
                    eye_factor = 0.92
                else:
                    eye_factor = 0.85

        if is_profile:
            eye_factor = 0.40

        # Looking at screen condition: Centered frontal face within main 75% field of view
        looking_at_screen = bool(center_proximity > 0.20 and not is_profile)

        # Adaptive Lip / Mouth Movement & Expression Detection
        mouth_y1 = y + int(fh * 0.60)
        mouth_y2 = min(sw_h, y + int(fh * 0.98))
        mouth_x1 = max(0, x + int(fw * 0.18))
        mouth_x2 = min(sw_w, x + int(fw * 0.82))

        mouth_motion_score = 0.0
        if mouth_y2 > mouth_y1 and mouth_x2 > mouth_x1:
            mouth_raw = gray_eq[mouth_y1:mouth_y2, mouth_x1:mouth_x2]
            mouth_normalized = cv2.resize(mouth_raw, (64, 40), interpolation=cv2.INTER_AREA)

            prev_mouth = _SESSION_PREV_MOUTH_ROIS.get(session_id)
            _SESSION_PREV_MOUTH_ROIS[session_id] = mouth_normalized

            # 1. Temporal motion diff between consecutive video frames
            motion_energy = 0.0
            if prev_mouth is not None and prev_mouth.shape == mouth_normalized.shape:
                diff = cv2.absdiff(mouth_normalized, prev_mouth)
                motion_energy = float(np.mean(diff))

            # 2. Smile / Expression detection
            smile_detected = False
            if SMILE_CASCADE is not None:
                smiles = SMILE_CASCADE.detectMultiScale(
                    mouth_raw,
                    scaleFactor=1.12,
                    minNeighbors=6,
                    minSize=(12, 12),
                )
                smile_detected = len(smiles) > 0

            # 3. Dynamic lip gradient / open-mouth variance (Laplacian texture variance)
            laplacian_var = float(cv2.Laplacian(mouth_normalized, cv2.CV_64F).var())
            is_articulating = laplacian_var > 55.0 or smile_detected

            mouth_movement = motion_energy > 1.8 or is_articulating
            mouth_motion_score = min(1.0, max(motion_energy / 5.0, 0.75 if is_articulating else 0.0))
        else:
            mouth_movement = False
            mouth_motion_score = 0.0

        # Compute Continuous Engagement Score
        if looking_at_screen:
            raw_engagement_score = (
                76.0 +
                (center_proximity * 14.0) +
                (eye_factor * 6.0) +
                (mouth_motion_score * 4.0)
            )
        else:
            raw_engagement_score = (
                (center_proximity * 25.0) +
                (eye_factor * 15.0) +
                10.0
            )

        raw_engagement_score = max(0.0, min(100.0, raw_engagement_score))
    else:
        face_detected = False
        looking_at_screen = False
        mouth_movement = False
        raw_engagement_score = 0.0
        _SESSION_PREV_MOUTH_ROIS.pop(session_id, None)

    # Exponential Moving Average for smooth non-jittery score updates
    prev_score = _SESSION_SMOOTHED_SCORES.get(session_id, raw_engagement_score)
    if face_detected:
        smoothed = (prev_score * 0.30) + (raw_engagement_score * 0.70)
    else:
        smoothed = max(0.0, prev_score * 0.4)

    _SESSION_SMOOTHED_SCORES[session_id] = smoothed
    final_score = int(round(max(0.0, min(100.0, smoothed))))

    return {
        "faceDetected": face_detected,
        "lookingAtScreen": looking_at_screen,
        "mouthMovement": mouth_movement,
        "engagementScore": final_score,
    }


@router.post("/engagement", response_model=EngagementAnalysisEvent)
async def analyze_engagement(
    file: UploadFile = File(...),
    childId: str = Form("A001"),
    sessionId: str = Form("SES_001"),
    activityId: str = Form("netaji_voice_01"),
):
    """
    Analyzes uploaded image frame and returns a standardized ENGAGEMENT_ANALYSIS event.
    Only reports observations — does NOT recommend any actions.
    """
    frame_bytes = await file.read()
    obs = _analyze_frame(frame_bytes, session_id=sessionId)

    data = EngagementData(**obs)

    return EngagementAnalysisEvent(
        source="python_vision",
        eventType="ENGAGEMENT_ANALYSIS",
        childId=childId,
        sessionId=sessionId,
        activityId=activityId,
        timestamp=datetime.now(timezone.utc).isoformat(),
        data=data,
    )

