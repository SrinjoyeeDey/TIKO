"""
POST /analyze/engagement
Accepts a camera image frame and returns ENGAGEMENT_ANALYSIS event JSON.
Reports ONLY observations (face, gaze, mouth movement, score).
Uses CLAHE lighting equalization, multi-cascade ensemble face detection,
geometric gaze alignment, head pose estimation, and temporal mouth motion tracking.
"""
from __future__ import annotations
from importlib import import_module
from pathlib import Path
from datetime import datetime, timezone
import math
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from fastapi import APIRouter, UploadFile, File, Form

from ..schemas import EngagementAnalysisEvent, EngagementData

cv2: Any = None
try:
    import cv2 as _cv2  # type: ignore
    cv2 = _cv2
except Exception:
    try:
        cv2 = import_module("cv2")
    except Exception:
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


def _load_cascade(filename: str) -> Optional[Any]:
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
_SESSION_LAST_FACE_BOX: Dict[str, Tuple[int, int, int, int]] = {}
_SESSION_CONSECUTIVE_MISSES: Dict[str, int] = {}


def _is_valid_face_candidate(gray_img: np.ndarray, x: int, y: int, w: int, h: int, is_profile: bool = False) -> bool:
    """
    Validates face bounding box geometry to reliably accept real human faces
    and reject zero-size or full-frame bounding box errors.
    """
    if gray_img is None or cv2 is None:
        return False

    sw_h, sw_w = gray_img.shape[:2]
    # 1. Reject tiny noise fragments (< 20px)
    if w < 20 or h < 20:
        return False

    # 2. Reject bounding box taking over entire frame (> 98%)
    if w > int(sw_w * 0.98) and h > int(sw_h * 0.98):
        return False

    # 3. Broad aspect ratio check (0.50 to 1.85) to accept natural head angles
    aspect_ratio = float(h) / float(w) if w > 0 else 0.0
    if not (0.50 <= aspect_ratio <= 1.85):
        return False

    return True


def _detect_faces_robust(gray_img: np.ndarray, clahe_img: np.ndarray, last_box: Optional[Tuple[int, int, int, int]] = None) -> Tuple[List[List[int]], bool]:
    """
    Robust multi-tier face detection using tree-based cascades resistant to curtains:
      - Checks local ROI around last known face box first
      - Runs tree-based ALT2 and ALT cascades
      - Runs PROFILE cascade on normal (left profile) and flipped (right profile) frames
    """
    _ensure_cascades()
    sw_h, sw_w = gray_img.shape[:2]
    min_size = (max(28, int(sw_w * 0.05)), max(28, int(sw_h * 0.05)))

    # 0. Local ROI Search around last known face
    if last_box is not None:
        lx, ly, lw, lh = last_box
        pad_x = int(lw * 0.35)
        pad_y = int(lh * 0.35)
        rx1 = max(0, lx - pad_x)
        ry1 = max(0, ly - pad_y)
        rx2 = min(sw_w, lx + lw + pad_x)
        ry2 = min(sw_h, ly + lh + pad_y)
        if ry2 > ry1 and rx2 > rx1:
            roi_clahe = clahe_img[ry1:ry2, rx1:rx2]
            if roi_clahe.shape[0] > min_size[1] and roi_clahe.shape[1] > min_size[0]:
                cascade_to_test = FACE_CASCADE_ALT2 or FACE_CASCADE_ALT
                if cascade_to_test is not None:
                    try:
                        local_faces = cascade_to_test.detectMultiScale(
                            roi_clahe,
                            scaleFactor=1.04,
                            minNeighbors=3,
                            minSize=min_size,
                        )
                        if len(local_faces) > 0:
                            global_faces = [[int(bx + rx1), int(by + ry1), int(bw), int(bh)] for (bx, by, bw, bh) in local_faces]
                            valid = [b for b in global_faces if _is_valid_face_candidate(gray_img, b[0], b[1], b[2], b[3], False)]
                            if len(valid) > 0:
                                return valid, False
                    except Exception:
                        pass

    # 1. Alt2 on CLAHE & Gray (Tree-based frontal face detector)
    for test_img in (clahe_img, gray_img):
        if FACE_CASCADE_ALT2 is not None and not FACE_CASCADE_ALT2.empty():
            try:
                faces = FACE_CASCADE_ALT2.detectMultiScale(
                    test_img,
                    scaleFactor=1.05,
                    minNeighbors=4,
                    minSize=min_size,
                )
                valid = [[int(b[0]), int(b[1]), int(b[2]), int(b[3])] for b in faces if _is_valid_face_candidate(gray_img, int(b[0]), int(b[1]), int(b[2]), int(b[3]), False)]
                if len(valid) > 0:
                    return valid, False
            except Exception:
                pass

    # 2. Alt on CLAHE & Gray
    for test_img in (clahe_img, gray_img):
        if FACE_CASCADE_ALT is not None and not FACE_CASCADE_ALT.empty():
            try:
                faces = FACE_CASCADE_ALT.detectMultiScale(
                    test_img,
                    scaleFactor=1.05,
                    minNeighbors=4,
                    minSize=min_size,
                )
                valid = [[int(b[0]), int(b[1]), int(b[2]), int(b[3])] for b in faces if _is_valid_face_candidate(gray_img, int(b[0]), int(b[1]), int(b[2]), int(b[3]), False)]
                if len(valid) > 0:
                    return valid, False
            except Exception:
                pass

    # 3. Default Frontal Cascade on CLAHE & Gray
    for test_img in (clahe_img, gray_img):
        if FACE_CASCADE_DEFAULT is not None and not FACE_CASCADE_DEFAULT.empty():
            try:
                faces = FACE_CASCADE_DEFAULT.detectMultiScale(
                    test_img,
                    scaleFactor=1.08,
                    minNeighbors=4,
                    minSize=min_size,
                )
                valid = [[int(b[0]), int(b[1]), int(b[2]), int(b[3])] for b in faces if _is_valid_face_candidate(gray_img, int(b[0]), int(b[1]), int(b[2]), int(b[3]), False)]
                if len(valid) > 0:
                    return valid, False
            except Exception:
                pass

    # 3. Profile (Left and Right profile via horizontal flip)
    if PROFILE_CASCADE is not None and not PROFILE_CASCADE.empty():
        try:
            # Left profile
            faces = PROFILE_CASCADE.detectMultiScale(
                clahe_img,
                scaleFactor=1.06,
                minNeighbors=4,
                minSize=min_size,
            )
            valid = [[int(b[0]), int(b[1]), int(b[2]), int(b[3])] for b in faces if _is_valid_face_candidate(gray_img, int(b[0]), int(b[1]), int(b[2]), int(b[3]), True)]
            if len(valid) > 0:
                return valid, True

            # Right profile (flip image horizontally)
            if cv2 is not None and clahe_img is not None and clahe_img.size > 0:
                flipped_clahe = cv2.flip(clahe_img, 1)  # type: ignore
                flipped_faces = PROFILE_CASCADE.detectMultiScale(
                    flipped_clahe,
                    scaleFactor=1.06,
                    minNeighbors=4,
                    minSize=min_size,
                )
                if len(flipped_faces) > 0:
                    unflipped = [[int(sw_w - (bx + bw)), int(by), int(bw), int(bh)] for (bx, by, bw, bh) in flipped_faces]
                    valid = [b for b in unflipped if _is_valid_face_candidate(gray_img, b[0], b[1], b[2], b[3], True)]
                    if len(valid) > 0:
                        return valid, True
        except Exception:
            pass

    return [], False


def _analyze_frame(frame_bytes: bytes, session_id: str = "default") -> dict:
    """
    Analyze a single image frame using OpenCV for:
      - High-sensitivity, persistent Face Detection with bi-directional profiles and ROI tracking
      - Continuous geometric Gaze Alignment calculation
      - Eye detection with eyeglasses-aware Haar cascade
      - Adaptive lip movement tracking via normalized difference & edge variance
      - Real-time smooth engagement scoring (0-100%)
      - Head Pose & Facial Expression estimation
    """
    if cv2 is None:
        _SESSION_SMOOTHED_SCORES[session_id] = 0.0
        _SESSION_PREV_MOUTH_ROIS.pop(session_id, None)
        _SESSION_LAST_FACE_BOX.pop(session_id, None)
        _SESSION_CONSECUTIVE_MISSES[session_id] = 0
        return {
            "faceDetected": False,
            "lookingAtScreen": False,
            "mouthMovement": False,
            "engagementScore": 0,
            "personDetected": False,
            "mouthOpen": False,
            "facialExpression": "NO_FACE",
            "headOrientation": "UNKNOWN",
            "headPose": None,
            "faceBox": [],
        }

    try:
        nparr = np.frombuffer(frame_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    except Exception:
        frame = None

    if frame is None or frame.size == 0:
        _SESSION_SMOOTHED_SCORES[session_id] = 0.0
        _SESSION_PREV_MOUTH_ROIS.pop(session_id, None)
        _SESSION_LAST_FACE_BOX.pop(session_id, None)
        _SESSION_CONSECUTIVE_MISSES[session_id] = 0
        return {
            "faceDetected": False,
            "lookingAtScreen": False,
            "mouthMovement": False,
            "engagementScore": 0,
            "personDetected": False,
            "mouthOpen": False,
            "facialExpression": "NO_FACE",
            "headOrientation": "UNKNOWN",
            "headPose": None,
            "faceBox": [],
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

    # 1. Multi-tier Validated Cascade Face Detection with ROI search
    last_box = _SESSION_LAST_FACE_BOX.get(session_id)
    faces, is_profile = _detect_faces_robust(gray, gray_eq, last_box=last_box)
    face_detected = len(faces) > 0

    if not face_detected:
        # Check temporal persistence buffer for momentary 1-2 frame webcam dropouts
        misses = _SESSION_CONSECUTIVE_MISSES.get(session_id, 0) + 1
        _SESSION_CONSECUTIVE_MISSES[session_id] = misses

        prev_score = _SESSION_SMOOTHED_SCORES.get(session_id, 0.0)
        if misses <= 2 and prev_score > 20.0 and last_box is not None:
            # Maintain brief temporal holdover (motion blur / nod / blink) with decayed score
            decayed_score = int(round(prev_score * 0.85))
            _SESSION_SMOOTHED_SCORES[session_id] = float(decayed_score)
            lx, ly, lw, lh = last_box
            return {
                "faceDetected": True,
                "lookingAtScreen": True,
                "mouthMovement": False,
                "engagementScore": decayed_score,
                "personDetected": True,
                "mouthOpen": False,
                "facialExpression": "ATTENTIVE",
                "headOrientation": "FRONTAL",
                "headPose": {"yaw": 0.0, "pitch": 0.0, "roll": 0.0},
                "faceBox": [int(lx), int(ly), int(lw), int(lh)],
            }

        # After >2 misses or when no face was previously seen: hard reset
        _SESSION_SMOOTHED_SCORES[session_id] = 0.0
        _SESSION_PREV_MOUTH_ROIS.pop(session_id, None)
        _SESSION_LAST_FACE_BOX.pop(session_id, None)
        return {
            "faceDetected": False,
            "lookingAtScreen": False,
            "mouthMovement": False,
            "engagementScore": 0,
            "personDetected": False,
            "mouthOpen": False,
            "facialExpression": "NO_FACE",
            "headOrientation": "UNKNOWN",
            "headPose": None,
            "faceBox": [],
        }

    # Reset consecutive misses on successful detection
    _SESSION_CONSECUTIVE_MISSES[session_id] = 0

    # Pick largest detected face
    faces_sorted = sorted(faces, key=lambda b: b[2] * b[3], reverse=True)
    x, y, fw, fh = faces_sorted[0]
    _SESSION_LAST_FACE_BOX[session_id] = (int(x), int(y), int(fw), int(fh))
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
        try:
            ey1 = max(0, y)
            ey2 = min(sw_h, y + int(fh * 0.55))
            ex1 = max(0, x)
            ex2 = min(sw_w, x + fw)
            upper_face = gray_eq[ey1:ey2, ex1:ex2]
            if upper_face.size > 0 and upper_face.shape[0] >= 10 and upper_face.shape[1] >= 10:
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
        except Exception:
            eye_factor = 0.85

    if is_profile:
        eye_factor = 0.40

    # Looking at screen condition: Centered frontal face within main 75% field of view
    looking_at_screen = bool(center_proximity > 0.20 and not is_profile)

    # Adaptive Lip / Mouth Movement & Expression Detection
    mouth_y1 = max(0, y + int(fh * 0.60))
    mouth_y2 = min(sw_h, y + int(fh * 0.98))
    mouth_x1 = max(0, x + int(fw * 0.18))
    mouth_x2 = min(sw_w, x + int(fw * 0.82))

    mouth_motion_score = 0.0
    mouth_open = False
    smile_detected = False

    if mouth_y2 > mouth_y1 and mouth_x2 > mouth_x1:
        try:
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
            if SMILE_CASCADE is not None:
                smiles = SMILE_CASCADE.detectMultiScale(
                    mouth_raw,
                    scaleFactor=1.12,
                    minNeighbors=6,
                    minSize=(12, 12),
                )
                smile_detected = len(smiles) > 0

            # 3. Dynamic lip gradient / open-mouth variance & aspect ratio calculation
            laplacian_var = float(cv2.Laplacian(mouth_normalized, cv2.CV_64F).var())

            # Calculate dark inner cavity ratio in mouth region to accurately detect open mouth
            mouth_gray = cv2.GaussianBlur(mouth_normalized, (3, 3), 0)
            min_val, max_val, _, _ = cv2.minMaxLoc(mouth_gray)
            threshold_val = min_val + (max_val - min_val) * 0.35
            dark_pixels = np.sum(mouth_gray < threshold_val)
            dark_pixel_ratio = float(dark_pixels) / float(mouth_normalized.size)

            # Mouth open if inner dark cavity ratio is high or Laplacian edge variance indicates wide opening
            mouth_open = bool(dark_pixel_ratio > 0.22 and laplacian_var > 45.0)

            is_articulating = laplacian_var > 55.0 or smile_detected
            mouth_movement = motion_energy > 1.8 or is_articulating or mouth_open
            mouth_motion_score = min(1.0, max(motion_energy / 5.0, 0.75 if is_articulating else 0.0))
        except Exception:
            mouth_movement = False
            mouth_open = False
            smile_detected = False
            mouth_motion_score = 0.0
    else:
        mouth_movement = False
        mouth_open = False
        smile_detected = False
        mouth_motion_score = 0.0

    # 4. 3D Head Pose (Yaw / Pitch / Roll) & Orientation Estimation via OpenCV SolvePnP
    yaw_deg = float((face_cx - (sw_w / 2.0)) / (sw_w / 2.0) * 45.0)
    pitch_deg = float((face_cy - (sw_h / 2.0)) / (sw_h / 2.0) * 35.0)
    roll_deg = 0.0

    try:
        model_points = np.array([
            (0.0, 0.0, 0.0),             # Nose tip
            (0.0, -330.0, -65.0),        # Chin
            (-225.0, 170.0, -135.0),     # Left eye
            (225.0, 170.0, -135.0),      # Right eye
            (-150.0, -150.0, -125.0),    # Left mouth
            (150.0, -150.0, -125.0)      # Right mouth
        ], dtype=np.float64)

        image_points = np.array([
            (face_cx, face_cy),
            (face_cx, face_cy + fh * 0.40),
            (face_cx - fw * 0.25, face_cy - fh * 0.15),
            (face_cx + fw * 0.25, face_cy - fh * 0.15),
            (face_cx - fw * 0.20, face_cy + fh * 0.25),
            (face_cx + fw * 0.20, face_cy + fh * 0.25)
        ], dtype=np.float64)

        focal_length = float(sw_w)
        camera_matrix = np.array([
            [focal_length, 0.0, sw_w / 2.0],
            [0.0, focal_length, sw_h / 2.0],
            [0.0, 0.0, 1.0]
        ], dtype=np.float64)
        dist_coeffs = np.zeros((4, 1), dtype=np.float64)

        success, rvec, tvec = cv2.solvePnP(model_points, image_points, camera_matrix, dist_coeffs, flags=cv2.SOLVEPNP_ITERATIVE)
        if success:
            rmat, _ = cv2.Rodrigues(rvec)
            proj_matrix = np.hstack((rmat, tvec))
            euler_angles = cv2.decomposeProjectionMatrix(proj_matrix)[6]
            pitch_deg = float(euler_angles[0][0])
            yaw_deg = float(euler_angles[1][0])
            roll_deg = float(euler_angles[2][0])
    except Exception:
        pass

    if is_profile:
        head_orientation = "PROFILE_LEFT" if norm_dx < 0.5 else "PROFILE_RIGHT"
        yaw_deg = -55.0 if norm_dx < 0.5 else 55.0
    elif norm_dy > 0.40 or pitch_deg > 25.0:
        head_orientation = "LOOKING_DOWN"
    elif norm_dx > 0.40 or abs(yaw_deg) > 30.0:
        head_orientation = "TURNED_AWAY"
    else:
        head_orientation = "FRONTAL"

    head_pose = {
        "yaw": round(yaw_deg, 1),
        "pitch": round(pitch_deg, 1),
        "roll": round(roll_deg, 1),
    }

    # 5. Facial Expression Classification (HAPPY, SAD, OPEN_MOUTH, ATTENTIVE, LOOKING_AWAY, NEUTRAL)
    if smile_detected:
        facial_expression = "HAPPY"
    elif mouth_open:
        facial_expression = "OPEN_MOUTH"
    elif looking_at_screen and center_proximity > 0.40:
        facial_expression = "ATTENTIVE"
    elif not looking_at_screen:
        facial_expression = "LOOKING_AWAY"
    else:
        facial_expression = "NEUTRAL"

    # Compute Continuous Engagement Score for active face
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

    # Exponential Moving Average for smooth non-jittery score updates while face is tracked
    prev_score = _SESSION_SMOOTHED_SCORES.get(session_id, raw_engagement_score)
    if prev_score > 0:
        smoothed = (prev_score * 0.30) + (raw_engagement_score * 0.70)
    else:
        smoothed = raw_engagement_score

    _SESSION_SMOOTHED_SCORES[session_id] = smoothed
    final_score = int(round(max(0.0, min(100.0, smoothed))))

    return {
        "faceDetected": face_detected,
        "lookingAtScreen": looking_at_screen,
        "mouthMovement": mouth_movement,
        "engagementScore": final_score,
        "personDetected": True,
        "mouthOpen": mouth_open,
        "facialExpression": facial_expression,
        "headOrientation": head_orientation,
        "headPose": head_pose,
        "faceBox": [int(x), int(y), int(fw), int(fh)],
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
    try:
        frame_bytes = await file.read()
    except Exception:
        frame_bytes = b""

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
