# TIKO — NIMO: The Warrior

An adaptive, voice-guided learning game about Indian heritage, culture and history.

Children travel across a hand-drawn map of India, watch short documentary clips about
Indian dance forms and freedom fighters, and then answer questions about what they saw —
by tapping, dragging, matching images, or **speaking aloud**. A Python AI service scores
their pronunciation, watches engagement through the camera, narrates questions with
text-to-speech, and recalibrates difficulty after every level. Parents get a PIN-protected
dashboard with a clinical-style progress report.

Built as a Smart India Hackathon (SIH) project.

---

## Table of contents

- [What's in the game](#whats-in-the-game)
- [Heritage content](#heritage-content)
- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Data model](#data-model)
- [API reference](#api-reference)
- [Adaptive difficulty](#adaptive-difficulty)
- [Content authoring](#content-authoring)
- [Testing](#testing)
- [Security notes](#security-notes)
- [Known issues](#known-issues)

---

## What's in the game

### The journey

A cinematic intro unfolds a parchment world map from Japan and flies into India
(`lib/journey/screens/map_journey_intro_screen.dart`). From there the child lands on the
main shell — a five-page vertical flow that doubles as onboarding and as the level hub
(`lib/screens/sego_concept_screen.dart`):

| Page | What happens |
| --- | --- |
| 0 | Emotion check-in — "How was your day?" with a mood slider |
| 1 | Age selection (3–15). The whole theme lerps green → yellow → pink → purple with age |
| 2 | Developmental questionnaire + speech-level self-rating → seeds the initial difficulty |
| 3 | Quest / category grid |
| 4 | Stepping-stone level map with a stats header and bottom nav |

Returning children skip straight to page 3.

### The learning loop

```
Level map  →  1913 heritage map  →  State story collection
                                          ↓
                        Video (with synced captions)
                                          ↓
                        Questions (5 types, AI-narrated)
                                          ↓
                        Level clear (stars, confetti, AI congratulation)
                                          ↓
                        Adaptive difficulty recalibration
```

### Question types

Five, all in `lib/qa_pipeline/widgets/`:

- **MCQ** — four options, single answer
- **Descriptive** — free text graded offline by cosine similarity against key concepts
  (`lib/qa_pipeline/services/keyword_matcher.dart`, uses `vector_math`)
- **Speech** — the child says a target phrase; up to 8 s of mono 16 kHz WAV goes to the
  Python service, which returns a pronunciation score and transcript
- **Sequence** — drag events into chronological order
- **Image matching** — match historical photographs to descriptions

### Maps of India

Three separate map implementations, all interactive:

- **Vector state map** — `lib/data/india_map_data.dart` holds generated GeoJSON polygons
  for all 28 states + 8 UTs in normalised coordinates, with per-state culture data
  (capital, language, food, famous-for, fun fact) in `lib/data/india_states_data.dart`.
- **3D "ground" map** — `lib/widgets/ground_india_map_widget.dart` renders the same
  polygons flat on the ground under perspective (`Matrix4` with `rotateX(~0.95 rad)`),
  with pan/zoom, matrix-inverted hit testing, a compass rose, trade-route arcs and a
  golden light pillar over the selected state.
- **1913 web map** — a separate web build in `assets/1913-game-map/`, embedded via
  `webview_windows` on Windows and an iframe + `postMessage` bridge on web
  (`lib/screens/game_map_1913_platform_*.dart`).

### Mini-games

Six standalone skill activities in `lib/features/activities/`, each with its own
difficulty config, engine, models and widgets:

| Activity | Skill trained |
| --- | --- |
| Catch NIMO | Attention, reaction time |
| Remember NIMO | Visual memory |
| Echo NIMO | Auditory sequencing |
| Find NIMO | Spatial search |
| Category Sort | Semantic categorisation |
| Turn NIMO | Turn-taking, motor control |

### Panda companion

An 8-frame-per-state sprite mascot (`lib/core/widgets/panda_character.dart`) with six
animations — `appear`, `idle`, `thinking`, `correct`, `celebrate`, `wrong_sad` — that chain
into each other (`correct → celebrate → idle`). It reacts to every answer, floats while
idle, and can be poked. All 48 frames are precached at boot.

### Voice and accessibility

- Every question can be **read aloud** via the "READ AI" button (ElevenLabs TTS through
  the Python service, falling back to `edge-tts`, then `gTTS`, then browser speech
  synthesis). Mute and replay supported. `lib/core/services/ai_voice_service.dart`
- **Synced captions** over every heritage video (`caption_overlay.dart`)
- **Engagement telemetry** — a front-camera JPEG every 1500 ms is analysed by OpenCV for
  face presence, gaze alignment and mouth articulation, surfaced in a minimisable HUD
  (`camera_engagement_overlay.dart`)
- Difficulty accommodation driven by the onboarding developmental questionnaire

### Parent dashboard

PIN-gated (`lib/screens/parent_auth_screen.dart` → `parent_pin_screen.dart` →
`parent_dashboard.dart` → `parent_level_report.dart`). Shows per-skill progress, per-level
reports, and a generated clinical-style report covering sensory/attention, speech and
communication, cognitive and motor skills, behavioural observations and actionable
insights.

---

## Heritage content

Two chapters ship with the app.

### Level 1 — Bharatanatyam (Tamil Nadu)

`assets/Bharatnatayam/` — five video parts with transcripts and question sets. Content
covers Bharatanatyam's origins in Tamil Nadu, its Tamil terminology, and the four-syllable
etymology:

| Syllable | Meaning |
| --- | --- |
| **Bha** | *bhava* — expression |
| **Ra** | *raga* — music |
| **Ta** | *thala* — rhythm |
| **Natyam** | dance |

### Level 2 — Netaji Subhas Chandra Bose (West Bengal)

`assets/Netaji/` — eleven levels (`Netaji_0` … `Netaji_10`). Covers his birth on
23 January 1897 to Janaki Nath Bose and Prabhavati Devi, his rustication from Presidency
College over the Professor Oaten incident, and his path to the freedom struggle.
`Netaji_0/images/` supplies the photographs used by the image-matching questions.

### In-code interactive stories

`lib/data/west_bengal_stories_database.dart` holds branching-choice stories with
historical-fact callouts:

- **Swami Vivekananda** — "The Boy Who Found His Voice"
- **Netaji Subhas Chandra Bose** — "The Call of Freedom"
- **British power in Calcutta**
- **The Bengal Renaissance**
- **Bharatanatyam (Tamil Nadu)** — "The Cosmic Dance of Expression", covering the
  *Natya Shastra* and the 108 Karanas carved at Brihadisvara Temple

`lib/data/babur_story_data.dart` feeds the steampunk chapter map in `story_map_screen.dart`.

Ten chapters are wired into the level map UI (Bharatanatyam, Netaji, Swami Dayanand,
Vivekananda, Bhagat Singh, Rani Lakshmibai, Subhashini, Rabindranath Tagore, …) but only
the first two have video assets today.

---

## Architecture

Three processes. The Flutter app is the source of truth for durable child data; the Python
service is a pure *observation provider*; the Node backend owns adaptive decisions and
telemetry aggregation.

```
┌──────────────────────────────────────────────┐
│  Flutter app  (peppa_p)                      │
│  Windows · Web · Android · iOS · macOS · Linux│
│                                              │
│  local SQLite (sqflite / IndexedDB on web)   │
│  qs_ans_learning_v2.db  ·  schema v7         │
└───────┬──────────────────────────┬───────────┘
        │ mic + camera + text      │ events, scoring, progress
        ▼                          ▼
┌───────────────────────┐   ┌──────────────────────────┐
│ Python FastAPI :8001  │   │ Node + Express :3000     │
│ "NIMO Contract API"   │   │ "peppa-backend"          │
│                       │   │                          │
│ • STT / pronunciation │   │ • event ingest           │
│ • OpenCV engagement   │──▶│ • scoring engine         │
│ • Groq difficulty LLM │   │ • progress + trends      │
│ • ElevenLabs TTS      │   │ • adaptive decisions     │
└───────────────────────┘   │ • recommendations        │
                            │ • clinical report        │
                            │ (in-memory stores)       │
                            └──────────────────────────┘
```

### Tech stack

**Client** — Flutter 3 / Dart SDK ^3.12.2
`media_kit` (video) · `sqflite` + `sqflite_common_ffi` + `sqflite_common_ffi_web` (storage)
`webview_flutter` / `webview_windows` (1913 map) · `camera` + `record` +
`permission_handler` (capture) · `confetti` · `google_fonts` · `vector_math` · `crypto` · `uuid`

**AI service** — FastAPI · Uvicorn · Pydantic
`SpeechRecognition` 3.17.0 (Google Web Speech) · `opencv-python-headless` (Haar cascades,
CLAHE, Sobel, Laplacian) · `groq` + `langchain-groq` (difficulty + dialogue) ·
ElevenLabs REST (`eleven_multilingual_v2`) · `edge-tts` / `gTTS` fallbacks · ffmpeg for
audio normalisation

**Backend** — Node.js · Express 4.19.2 · cors · dotenv. No database — in-memory stores
seeded with fixtures.

---

## Repository layout

```
TIKO/
├── lib/                          Flutter app
│   ├── main.dart                 entry: sqflite factory + MediaKit init → BootStrapWrapper
│   ├── core/
│   │   ├── api/                  9 HTTP clients for the Node backend
│   │   ├── models/               backend-mirroring models (child, session, event, activity…)
│   │   ├── services/             AI integration, voice, media capture, sync, parent repo
│   │   ├── state/                child_state.dart — app-wide child profile
│   │   └── widgets/              panda mascot, generic activity renderer
│   ├── data/                     India GeoJSON, state culture data, story databases
│   ├── features/activities/      6 mini-games + shared adaptive core
│   ├── journey/                  cinematic world → India intro
│   ├── qa_pipeline/              the video → question → report learning loop
│   │   ├── database/             SQLite helper + 6 repositories
│   │   ├── models/               questions, attempts, progress, clinical report
│   │   ├── screens/              chapter/level select, video, questions, level clear, parent
│   │   ├── services/             discovery, questions, transcripts, stars, analytics, reports
│   │   └── widgets/              one widget per question type, captions, camera overlay
│   ├── screens/                  app shell: onboarding, auth, maps, stories, leaderboard
│   └── widgets/                  themed component library (wood, steampunk, japanese)
├── ai_services/
│   └── nimo_contract_api/        FastAPI app — main.py, routes/, services/, schemas.py
├── backend/
│   └── src/                      server.js, routes/, controllers/, services/, models/, tests/
├── assets/
│   ├── Bharatnatayam/            5 levels — video + transcript.json + questions.json
│   ├── Netaji/                   11 levels — same structure + images/
│   ├── 1913-game-map/            embedded web map build
│   ├── animations/panda/         48 sprite frames + manifest.json + README
│   ├── audio/ images/ maps/ exploration/
├── question_Answer_pipeline/     standalone prototype Flutter app (superseded by lib/qa_pipeline)
├── scratch/validate_all.py       content QA gate — validates every questions.json
├── test/                         7 Dart test files
├── start_ai_service.bat / .ps1   launch the Python service on :8001
├── update_assets.ps1             regenerate the pubspec assets: block from the assets tree
└── requirements.txt              Python deps
```

---

## Getting started

### Prerequisites

- Flutter SDK 3.x (Dart ^3.12.2) — `flutter doctor` should be clean
- Python 3.10+
- Node.js 18+
- **ffmpeg on PATH** — required for speech audio normalisation (degrades gracefully if absent)
- A [Groq](https://console.groq.com) API key (adaptive difficulty + voice dialogue)
- An [ElevenLabs](https://elevenlabs.io) API key (optional — TTS falls back to `edge-tts`/`gTTS`)

### 1. Python AI service — port 8001

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install requests edge-tts gTTS    # runtime deps missing from requirements.txt

Copy-Item ai_services\.env.example ai_services\.env
# then fill in GROQ_API_KEY and ELEVENLABS_API_KEY

.\start_ai_service.ps1
```

Swagger UI: <http://localhost:8001/docs> · health: <http://localhost:8001/health>

The start script prefers `.venv\Scripts\python.exe`, sets `PYTHONPATH=.;ai_services`, and
runs `uvicorn ai_services.nimo_contract_api.main:app --reload --port 8001`.

### 2. Node backend — port 3000

```powershell
cd backend
npm install
npm run dev      # node --watch src/server.js
```

Health: <http://localhost:3000/api/health>

### 3. Flutter app

```powershell
flutter pub get
flutter run -d windows     # or: chrome, android, macos, linux
```

Windows and Web are the best-tested targets — the 1913 map embed only has platform
implementations for those two.

If you add or move asset files, regenerate the pubspec asset list:

```powershell
.\update_assets.ps1
```

The app runs standalone. Without the Python service, voice falls back to browser speech
synthesis and difficulty falls back to local heuristics. Without the Node backend, the
local SQLite store still records everything.

---

## Configuration

| Variable | Where | Purpose |
| --- | --- | --- |
| `GROQ_API_KEY` | `ai_services/.env` | Difficulty calibration + voice dialogue generation |
| `ELEVENLABS_API_KEY` | `ai_services/.env` | Text-to-speech narration |
| `ELEVENLABS_VOICE_ID` | `ai_services/.env` | Optional. Defaults to `21m00Tcm4TlvDq8ikWAM` ("Rachel") |
| `PORT` | `backend/` env | Backend port. Defaults to 3000 |

Env loading order for the Python service: `ai_services/.env` → root `.env` → ambient env.

### Hardcoded endpoints

| Client | Target |
| --- | --- |
| `lib/core/api/api_config.dart` | `http://localhost:3000/api`, `http://10.0.2.2:3000/api` on Android |
| `lib/core/services/ai_voice_service.dart` | `http://localhost:8001`, `http://10.0.2.2:8001` on Android |
| `lib/core/services/ai_integration_service.dart` | `http://localhost:8001` (no Android branch — see [Known issues](#known-issues)) |

### Groq model fallback chain

`openai/gpt-oss-20b` → `openai/gpt-oss-120b` → `qwen/qwen3.6-27b` → `allam-2-7b`, then a
local heuristic. Voice dialogue uses `llama-3.1-8b-instant`.

---

## Data model

Local SQLite: `qs_ans_learning_v2.db`, **schema version 7**, managed by
`lib/qa_pipeline/database/database_helper.dart`. Web uses `sqflite_common_ffi_web`
(IndexedDB-backed, needs `web/sqflite_sw.js` + `web/sqlite3.wasm`); desktop uses
`sqflite_common_ffi`; any failure falls back to an in-memory database.

| Table | Key columns |
| --- | --- |
| `parents` | `id` PK, `name`, `email` UNIQUE, `password_hash`, `pin_hash`, timestamps |
| `child_profiles` | `id` PK, `parent_id` FK, `name`, `age`, `class_name`, `difficulty_percentage`, `difficulty_level`, `difficulty_reasoning` |
| `level_progress` | PK (`child_id`, `chapter_id`, `level_id`), `completed`, `stars`, `completed_at` |
| `question_attempts` | `id` PK, child/chapter/level/question ids, `question_type`, timings, `is_correct`, `similarity_score`, `user_answer`, `correct_matches`, `total_matches` |
| `sessions` | `id` PK, `child_id`, `parent_id`, `started_at`, `ended_at`, `duration_seconds` |
| `activity_events` | `id` PK, `skill`, `difficulty`, `success`, `accuracy`, `reaction_time_ms`, `errors`, `attempt_number`, `input_type`, `synced` |
| `event_queue` | `id` PK, `event_json`, `created_at` — offline outbox for `SyncService` |
| `session_clinical_evaluations` | seven clinical dimensions + difficulty fields + `recommendations` |
| `child_onboarding_assessments` | `answers_json`, `developmental_diagnoses`, `speech_level_self_rating`, computed difficulty |
| `app_settings` | `key` PK, `value` — holds `remembered_child_id` |

Indexes: `idx_attempts_child_level`, `idx_attempts_child_type`.
Migrations: v3 adds image-matching columns · v4 adds `parent_id`, parents, sessions,
activity_events, event_queue · v5 adds difficulty columns · v6–v7 re-run table creation.

Passwords and 4-digit PINs are hashed with SHA-256 via `crypto`
(`lib/core/services/parent_repository.dart`).

---

## API reference

### Python AI service — `:8001`

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | Status + loaded models |
| POST | `/analyze/speech` | multipart audio + `targetPhrase` → `SPEECH_ANALYSIS` event with pronunciation score and transcript |
| POST | `/analyze/engagement` | multipart JPEG frame → `ENGAGEMENT_ANALYSIS` event |
| POST | `/calculate/difficulty` | Initial difficulty from profile + onboarding answers |
| POST | `/calculate/adaptive-difficulty` | Post-level recalibration from 7 clinical dimensions |
| POST | `/voice/interaction` | Dialogue + TTS for `POST_SIGNUP_INTRO`, `READ_QUESTION`, `PRONOUNCE_PHRASE`, `RETRY_QUESTION`, `LEVEL_COMPLETION`, `CUSTOM` |
| POST | `/voice/tts` | Direct TTS → `audioId` / `audioUrl` / base64 |
| GET | `/voice/audio/{audio_id}` | Stream cached MP3 |
| GET | `/voice/status` | Key configuration + cached audio count |

`/assess/*` and `/calculate/adaptive` are registered aliases of the difficulty routes.

**Speech scoring** — ffmpeg normalises to 16 kHz mono PCM with highpass 80 Hz, lowpass
7500 Hz, `dynaudnorm` and 2.5× gain. Recognition tries `en-IN` → `en-US` → `hi-IN` →
`en-GB`. Phonetic normalisation handles Indian transliterations and childhood lisping.
Final score blends `SequenceMatcher` ratio (35%) with token overlap (65%).

**Engagement** — Haar cascades (frontal alt2/alt/default, profile, eye, eye+glasses,
smile) over CLAHE-equalised frames, with Sobel gradient validation to reject flat
backgrounds like curtains, geometric gaze alignment, Laplacian mouth-articulation
variance, and per-session EMA smoothing.

**TTS caching** — two tiers: in-memory plus `ai_services/.audio_cache/*.mp3`, keyed by
SHA-256 of the text + voice.

Full request/response contracts for the two `/analyze/*` endpoints, including
no-detection payloads and cURL examples, live in
`ai_services/nimo_contract_api/README.md`.

### Node backend — `:3000`

All paths are prefixed `/api`.

**Parents and children**
`POST /parents/signup` · `POST /parents/set-pin` · `POST /parents/verify-pin` ·
`GET|POST /parents/:parentId/children` · `GET /children` · `GET /children/:id` ·
`POST /children` · `PATCH /children/:id`

**Sessions**
`POST /sessions` · `GET /sessions/:sessionId` · `PATCH /sessions/:sessionId` ·
`PATCH /sessions/:sessionId/end` · `POST /sessions/:sessionId/interactions`

**Activities and results**
`POST /activities` · `GET /activities/:activityId` · `GET /stories/:storyId/activities` ·
`GET /results/:sessionId` · `GET /results/child/:childId`

**Events and scoring**
`POST /events` · `GET /events?sessionId=&childId=` · `POST /scoring/evaluate` ·
`POST /integrations/events` · `GET /integrations/mocks`

**Progress and adaptation**
`GET /children/:childId/progress` · `/progress/history` · `/progress/:skill` ·
`GET /children/:childId/report` · `GET /children/:childId/next-activity?skill=` ·
`POST /adaptive/evaluate` · `GET /children/:childId/recommendation`

**Engines**

- `scoringService` — `score = 100 − (attempts−1)×15 − hints×10 − timePenalty`;
  `xp = reward × score / 100`
- `progressService` — rolling average `old×0.7 + new×0.3`, trend detection at ±5
- `adaptiveService` — 5-activity sliding window, difficulty clamped 1–3
- `recommendationService` — priority = skill need 40% + trend 20% + difficulty match 25%
  + novelty 15%
- `integrationService` — whitelists sources (`flutter`, `python_speech`, `python_vision`,
  `esp32`, `mock_hardware`) and 20 event types; range-validates
  `pronunciationScore` 0–100, `confidence` 0.0–1.0, `engagementScore` 0–100

---

## Adaptive difficulty

Difficulty is a 0–100 percentage mapped onto five named bands, used consistently across
the Python prompts, the Dart models and the question bank:

| Band | Range |
| --- | --- |
| Gentle Starter | 10–35 |
| Balanced Explorer | 36–50 |
| Curious Adventurer | 51–65 |
| Challenger | 66–80 |
| Champion | 81–95 |

Three layers adapt independently:

**Onboarding** — the age, developmental questionnaire and speech self-rating from
`SegoConceptScreen` go to `POST /calculate/difficulty`. Groq returns a percentage, band
and reasoning, stored on `child_profiles`.

**Within a mini-game** — `lib/features/activities/core/services/adaptive_learning_service.dart`
runs a 3-attempt sliding window: promote at accuracy ≥ 0.80 with mean reaction < 1200 ms,
demote below 0.50, clamped to levels 1–6.

**Between levels** — after each level clear, seven clinical dimensions go to
`POST /calculate/adaptive-difficulty`. The returned band then filters the question bank in
`QuestionService.loadQuestionsForChild`:

| Child band | Questions served |
| --- | --- |
| ≤ 35 | ≤ 45% |
| ≤ 50 | 25–60% |
| ≤ 65 | 40–75% |
| ≤ 80 | 50–90% |
| > 80 | ≥ 65% |

If a band comes up empty, the full set is used.

**Stars** — `StarCalculator`: accuracy ≥ 0.80 → 3 stars, ≥ 0.50 → 2, otherwise 1. A
completed level never scores 0; a level with no questions returns 3 for watching the video.

**Unlocking** is strictly linear, derived from `level_progress`. The first uncompleted
level is the furthest reachable one; tapping a locked node fires haptic feedback and a
"complete X first" prompt.

---

## Content authoring

Levels are **discovered at runtime, not declared**.
`lib/qa_pipeline/services/content_discovery_service.dart` reads the Flutter `AssetManifest`
and treats `assets/<Chapter>/<Level>/` as a level. A level is playable if the folder
contains a video (`.mp4`/`.mkv`/`.avi`, preferring `video.mp4`). `transcript.json` and
`questions.json` are optional. Levels sort naturally (`Netaji_2` before `Netaji_10`) and
display numbers are offset by one, so `Netaji_0` reads as "Netaji 1".

To add a level:

```
assets/<Chapter>/<Chapter>_<n>/
├── video.mp4
├── transcript.json
├── questions.json
└── images/            (optional, for image-matching questions)
```

Then run `.\update_assets.ps1` and `flutter pub get`.

### `transcript.json`

```json
{
  "segments": [
    { "start": 0.0, "end": 12.0, "text": "Bharatanatyam comes from Tamil Nadu…" }
  ]
}
```

### `questions.json`

Root keys: `title`, `section` (`start`/`end`/`description`), `target_age`, `age_range`,
`question_pattern`, `questions`, `sequence_test`, `image_matching`, `scoring`.

Each entry in `questions` carries `difficulty`, `difficulty_percentage`,
`difficulty_level` and `target_age_group`, plus type-specific fields:

| Type | Fields |
| --- | --- |
| `mcq` | `options` (A–D map), `answer`, `answer_text` |
| `descriptive` | `reference_answer`, `key_concepts`, `cosine_similarity_threshold` |
| `speech` | `target_phrase`, `key_concepts`, `min_score_threshold` |

`sequence_test` holds items + correct order; `image_matching` holds images, descriptions
and correct pairings.

The convention across shipped files is 45 questions per level — roughly 25 MCQ, 9
descriptive, 11 speech — split 15 easy (ages 3–7) / 15 moderate (8–11) / 15 hard (12–15),
plus 2 sequence questions and 2 image-matching sets.

### Validating content

```powershell
python scratch\validate_all.py
```

Checks transcript segment shape, all 9 root keys, question counts, per-type required
fields, sequence and image-matching counts, and all 5 scoring keys. Prints difficulty and
type breakdowns. Note its folder list was written against an earlier asset layout — see
[Known issues](#known-issues).

---

## Testing

**Flutter** — 7 files in `test/`:

```powershell
flutter test
```

| File | Covers |
| --- | --- |
| `widget_test.dart` | Boot smoke test |
| `panda_character_test.dart` | 6 animations × 8 frames, path formatting, appear→idle lifecycle |
| `child_difficulty_test.dart` | Difficulty field serialisation on both `ChildProfile` classes |
| `question_difficulty_filtering_test.dart` | `fromJson` for all 5 question types + percentage fallback |
| `adaptive_difficulty_session_evaluation_test.dart` | `SessionClinicalEvaluation` round-trip |
| `parent_repository_persistence_test.dart` | Real SQLite: parent create, PIN set/verify, auto-linked child |
| `content_discovery_test.dart` | Level video prioritisation |

**Backend** — 13 hand-rolled assert cases over the integration event layer:

```powershell
cd backend
npm test
```

---

## Security notes

This is a hackathon prototype. Before any real deployment:

- **`ai_services/.env` is committed to git with live API keys.** Rotate the Groq and
  ElevenLabs keys, add `ai_services/.env` to `.gitignore`, and purge it from history.
- **The Node backend has no authentication.** Every endpoint is open — no tokens, no
  session middleware, no route guards.
- **Password and PIN hashing is unsalted single-pass SHA-256** on both the client and the
  backend. Use a KDF (bcrypt/argon2) with per-user salts.
- **`POST /parents/verify-pin` without a `parentId` matches any parent** sharing that PIN
  hash. With 4-digit PINs that is trivially brute-forceable.
- **CORS is fully open** on both services (`allow_origins=["*"]` and bare `cors()`).
- The app captures **camera frames and microphone audio of children** and sends them to
  localhost services. Real deployment needs explicit parental consent, a retention policy,
  and transport encryption.

---

## Known issues

- `ai_services/.env` is tracked in git with live keys — see [Security notes](#security-notes).
- `requirements.txt` omits three runtime imports: `requests`, `edge-tts`, `gTTS`. They are
  wrapped in try/except so the service starts, but TTS fallback fails silently. Install
  them manually.
- `ai_integration_service.dart` hardcodes `http://localhost:8001` with no `10.0.2.2`
  branch, so speech and engagement analysis cannot reach the service from an Android
  emulator. `ai_voice_service.dart` handles this correctly.
- `pyrightconfig.json` hardcodes a machine-specific site-packages path for a different
  user; it will not resolve elsewhere.
- `prism-aac/` is an empty directory recorded as a submodule gitlink with no
  `.gitmodules` entry. Either initialise it or remove the gitlink.
- `scratch/validate_all.py` checks a folder list that no longer matches `assets/`.
- Asset folder spelling is inconsistent: `assets/Bharatnatayam/` contains
  `bharatnatayam_0…3` plus `bharatnatyam_4`. Discovery is filename-driven so it works,
  but it is a trap.
- `lib/screens/sego_concept_screen.dart` is ~10,500 lines holding all of onboarding plus
  the level map. Worth splitting.
- Duplicate parallel implementations: two `ChildProfile` classes (`core/models` and
  `qa_pipeline/models`), two `AdaptiveLearningService` classes, two `DifficultyConfig`
  classes, `catch_nimo/controllers/` vs `catch_nimo/engine/`, and two `main.dart` entry
  points (`lib/main.dart` is live; `lib/qa_pipeline/main.dart` is legacy).
- `question_Answer_pipeline/` is a superseded standalone prototype, kept for reference.
- Backend stores are in-memory and reset on restart. `LeaderboardScreen` data is local and
  not fetched. XP/level/streak on the child profile are seeded with placeholder values
  (350 / 4 / 5).
- `assets/animations/panda/README.md` flags that `appear` frames 03–07 are incomplete.
- `MapAudioService` is stubbed — `debugPrint` hooks only, no audio.
- `MapJourneyIntroScreen` has a `_reducedMotion` flag hardcoded to `false` with no UI
  toggle.

---

## Credits

Built for Smart India Hackathon.
Bharatanatyam segment sourced from the Kennedy Center "Teaching Artists Present" lesson by
dancer Deepa Mani.

Repository: <https://github.com/SrinjoyeeDey/TIKO>
