# NIMO Python Model — Integration Contract API

> **For the NIMO backend team.**
> This folder is the **standardized output layer** for the Python AI/ML model.
> The internal implementation (PyTorch, OpenCV, model files, preprocessing) is **not your concern**.
> You only need to consume the JSON responses from the two endpoints below.

---

## 📁 Folder Structure

```
nimo_contract_api/
├── main.py           ← FastAPI application entry point (port 8001)
├── schemas.py        ← Pydantic models — exactly matching the NIMO contract
├── requirements.txt  ← Python dependencies
├── README.md         ← This file
└── routes/
    ├── speech.py     ← POST /analyze/speech
    └── engagement.py ← POST /analyze/engagement
```

---

## ⚡ Quick Start

```bash
# 1. Install dependencies
pip install -r nimo_contract_api/requirements.txt

# 2. Start server (run from project root — one level above nimo_contract_api/)
uvicorn nimo_contract_api.main:app --reload --port 8001

# 3. View interactive Swagger docs
# http://localhost:8001/docs
```

---

## 🔗 Endpoints

---

### `POST /analyze/speech`
Analyzes child's voice audio. Returns a `SPEECH_ANALYSIS` event.

**Request:** `multipart/form-data`

| Field | Type | Required | Description |
|---|---|---|---|
| `file` | `.wav` audio | ✅ | Child's recorded speech |
| `childId` | string | ✅ | Child identifier (e.g. `A001`) |
| `sessionId` | string | ✅ | Session identifier (e.g. `SES_001`) |
| `activityId` | string | ✅ | Activity identifier (e.g. `netaji_voice_01`) |
| `targetPhrase` | string | optional | What the child was supposed to say (for scoring) |

**cURL Example:**
```bash
curl -X POST http://localhost:8001/analyze/speech \
  -F "file=@child_audio.wav" \
  -F "childId=A001" \
  -F "sessionId=SES_001" \
  -F "activityId=netaji_voice_01" \
  -F "targetPhrase=Subhas Chandra Bose"
```

**✅ Response (speech detected):**
```json
{
  "source": "python_speech",
  "eventType": "SPEECH_ANALYSIS",
  "childId": "A001",
  "sessionId": "SES_001",
  "activityId": "netaji_voice_01",
  "timestamp": "2026-08-15T10:00:00+00:00",
  "data": {
    "transcript": "Subhas Chandra Bose",
    "speechDetected": true,
    "speechAttempt": true,
    "pronunciationScore": 82,
    "responseTime": 4.8,
    "confidence": 0.91
  }
}
```

**✅ Response (no speech / unclear):**
```json
{
  "source": "python_speech",
  "eventType": "SPEECH_ANALYSIS",
  "childId": "A001",
  "sessionId": "SES_001",
  "activityId": "netaji_voice_01",
  "timestamp": "2026-08-15T10:00:01+00:00",
  "data": {
    "transcript": "",
    "speechDetected": false,
    "speechAttempt": false,
    "pronunciationScore": 0,
    "responseTime": 7.2,
    "confidence": 0.0
  }
}
```

---

### `POST /analyze/engagement`
Analyzes a single camera frame. Returns an `ENGAGEMENT_ANALYSIS` event.

**Request:** `multipart/form-data`

| Field | Type | Required | Description |
|---|---|---|---|
| `file` | image (JPEG/PNG) | ✅ | A single camera frame |
| `childId` | string | ✅ | Child identifier |
| `sessionId` | string | ✅ | Session identifier |
| `activityId` | string | ✅ | Activity identifier |

**cURL Example:**
```bash
curl -X POST http://localhost:8001/analyze/engagement \
  -F "file=@frame.jpg" \
  -F "childId=A001" \
  -F "sessionId=SES_001" \
  -F "activityId=netaji_voice_01"
```

**✅ Response (child engaged):**
```json
{
  "source": "python_vision",
  "eventType": "ENGAGEMENT_ANALYSIS",
  "childId": "A001",
  "sessionId": "SES_001",
  "activityId": "netaji_voice_01",
  "timestamp": "2026-08-15T10:00:00+00:00",
  "data": {
    "faceDetected": true,
    "lookingAtScreen": true,
    "mouthMovement": true,
    "engagementScore": 78
  }
}
```

**✅ Response (child distracted):**
```json
{
  "source": "python_vision",
  "eventType": "ENGAGEMENT_ANALYSIS",
  "childId": "A001",
  "sessionId": "SES_001",
  "activityId": "netaji_voice_01",
  "timestamp": "2026-08-15T10:00:02+00:00",
  "data": {
    "faceDetected": true,
    "lookingAtScreen": false,
    "mouthMovement": false,
    "engagementScore": 32
  }
}
```

---

## 📋 Event Types Used

| eventType | Source | When |
|---|---|---|
| `SPEECH_ANALYSIS` | `python_speech` | After every voice input attempt |
| `ENGAGEMENT_ANALYSIS` | `python_vision` | After each camera frame analysis |
| `ENGAGEMENT_SUMMARY` | `python_vision` | End of session aggregation |

---

## ⚠️ Integration Contract Rules

1. **This model is an observation provider only.** It does NOT decide activity difficulty, next steps, or rewards. That is the NIMO Adaptive Engine's job.
2. **Never send raw camera frames/audio to backend.** This model returns processed metrics only.
3. Field formats are strict:
   - `pronunciationScore` → integer, **0–100**
   - `confidence` → float, **0.0–1.0**
   - `engagementScore` → integer, **0–100**
4. Pass threshold for speech: `pronunciationScore >= 85`
5. The model will **never crash** or return a different JSON structure — it always returns the same shape, even if speech was not detected.

---

## 🧩 Architecture Position

```
Camera / Microphone
        ↓
  Python AI Model   ← (This service — port 8001)
        ↓
  Standardized JSON
        ↓
  NIMO Backend
        ↓
  Adaptive Engine → Decisions
```
