# Educational Gamified Learning App 🚀

Welcome to the Educational Gamified Learning App! This Flutter application is designed to provide children with an interactive, adaptive, and highly engaging learning experience. By blending video content with dynamic question sets, adaptive difficulty scaling, and comprehensive parent analytics, the app serves as a robust educational tool.

## 🌟 Implemented Features

### 1. Dynamic Content Discovery (`lib/services/content_discovery_service.dart`)
- **Asset Manifest Parsing**: The app dynamically discovers chapters, levels, videos, and question sets by scanning the `assets/` directory at runtime.
- **Dynamic File Resolution**: Automatically resolves image assets regardless of extension (`.png`, `.jpg`, `.avif`, etc.) dynamically, preventing hardcoded JSON errors.
- **Natural Sorting**: Automatically organizes levels in proper numerical order (e.g., Level_2 comes before Level_10).

### 2. Gamified Question Engine (`lib/models/`, `lib/widgets/`)
The core learning loop is driven by a robust JSON-backed question engine supporting multiple distinct interactive question types:
- **Multiple Choice (MCQ)**: Standard 4-option questions with immediate feedback.
- **Sequence Matching**: Drag-and-drop sequencing where learners arrange historical events or concepts in chronological order.
- **Descriptive Evaluation**: AI-backed offline NLP that evaluates free-text answers using a Cosine Similarity algorithm (`lib/services/keyword_matcher.dart`) against reference answers and key concepts.
- **Image Matching**: A highly interactive landscape-oriented game where learners match dynamic images to correct descriptions using `Draggable` and `DragTarget` widgets (`lib/widgets/image_matching_widget.dart`).
- **Dynamic Orientation Switching**: The app seamlessly locks into Landscape mode for Image Matching and returns to Portrait for other questions.

### 3. Adaptive Learning System (`lib/services/adaptive_learning_service.dart`)
- **Performance Tracking**: Monitors exactly how long a child takes per question and their historical accuracy.
- **Dynamic Intervention**: Automatically identifies when a child is struggling (e.g., low accuracy paired with high time spent) and dynamically reduces the frequency of those specific question types to prevent frustration.

### 4. Comprehensive Parent Dashboard (`lib/screens/parent_dashboard.dart`)
- **Pin Protected**: Secured gateway ensuring only parents can view analytics (`lib/screens/parent_pin_screen.dart`).
- **Progress Tracking**: Displays total levels completed, study time per section, and overall accuracy.
- **Concentration Report**: Provides actionable, child-friendly insights based on the Adaptive Learning System (e.g., "Performing well", "Needs Support").

### 5. Persistent SQLite Database (`lib/database/`)
- **Schema Migration Strategy**: Built with `sqflite` (and `sqflite_common_ffi` for desktop support) featuring non-destructive schema migrations (currently at `v3`).
- **Data Repositories**: Tracks granular question attempts (`QuestionAttemptRepository`), level completions and star ratings (`ProgressRepository`), and child profiles (`ChildRepository`).

### 6. Video & Transcript Integration (`lib/screens/video_player_screen.dart`)
- Fully integrated `media_kit` for cross-platform video playback.
- Displays timed, interactive transcript overlays (`lib/widgets/caption_overlay.dart`) that synchronize flawlessly with video playback timestamps.

### 7. Celebration & Gamification (`lib/screens/level_clear_screen.dart`)
- **Star System**: A mathematically robust star calculator (`lib/services/star_calculator.dart`) that awards 1-3 stars based on percentage thresholds.
- **Confetti & Animations**: Uses `Confetti` and custom staggered fade/scale animations (`lib/widgets/level_clear_animation.dart`) to reward the child upon completing a level.

## 📁 Project Architecture

```
lib/
├── database/            # SQLite implementation, migrations, and repositories
├── models/              # Dart Data classes (Questions, Progress, Stats)
├── screens/             # UI Pages (Dashboard, Questions, Video, Auth)
├── services/            # Business Logic (JSON Parsers, NLP, Adaptive Engine)
└── widgets/             # Reusable UI Components (Cards, Custom Question UIs)
```

## 🛠️ Tech Stack & Dependencies
- **Framework**: Flutter / Dart
- **Database**: `sqflite`
- **Video**: `media_kit`
- **NLP / Similarity**: `vector_math` (Cosine Similarity)
- **UI & Animations**: `confetti`, `google_fonts`, `cupertino_icons`

## 🚀 Getting Started
1. Ensure you have the Flutter SDK installed.
2. Run `flutter pub get` to install dependencies.
3. Use the `update_assets.ps1` PowerShell script to dynamically index new assets into `pubspec.yaml`.
4. Run `flutter run`!
