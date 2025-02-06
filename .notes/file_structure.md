# StockfishReel Overview & Architecture

## 1. Project Goals & Features

### Core Views / Flows:

- Landing Screen: A welcome or promotional page that introduces the app.
- Login / Sign Up: User authentication using Firebase Auth.
- Main Feed: A TikTok-style vertical feed displaying video posts with interactive elements (likes, follows, comments).
- Video Creation & Upload: A flow that allows creators to record or upload videos, process them, and publish them.

### Additional User Stories for Creators:

- Categorize & Tag Videos: Tag games by chess opening.
- Game Metadata Entry: Input metadata like ELO ratings, opponent ELO, site, date, and game result.
- Timestamp Insertion: Mark key game phases (opening, middlegame, endgame).
- Move Classification Animations: Overlay animations indicating move types.
- Move Annotation Side Panel: Show a side panel with move-by-move annotations.
- PGN Export: Allow exporting a game in PGN format.

## 2. Ideal File Structure

A modular file structure helps maintain clarity and scalability. Below is a recommended file/folder layout:
```
/stockfish_reel
├── android
├── assets
│   ├── images/
│   │   ├── logo.webp
│   │   └── background.png
├── ios
├── functions                     // Firebase Cloud Functions
│   ├── src/                     // TypeScript source files
│   │   ├── index.ts            // Functions entry point
│   │   ├── auth.ts             // Authentication related functions
│   │   └── types.ts            // TypeScript type definitions
│   ├── package.json            // Node.js dependencies
│   └── tsconfig.json           // TypeScript configuration
├── lib
│   ├── firebase_options.dart      // Firebase project configuration
│   ├── main.dart                  // Entry point of the app
│   ├── app.dart                   // App configuration and theme setup
│   │
│   ├── models/                    // Data models for your app
│   │   ├── user.dart              // User model (for Auth data and User collection)
│   │   ├── video.dart             // Video post model (includes metadata, tags, timestamps)
│   │   └── chess_game.dart        // Chess game specifics (moves, annotations, PGN data)
│   │
│   ├── views/                     // Screen-level widgets (pages)
│   │   ├── landing/               // Landing page view
│   │   │   └── landing_screen.dart
│   │   │
│   │   ├── auth/                  // Authentication-related screens
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   │
│   │   ├── feed/                  // Main feed and video display screens
│   │   │   ├── main_feed_screen.dart
│   │   │   └── video_detail_screen.dart  // (optional, if tapping a video expands details)
│   │   │
│   │   ├── video_upload/          // Video creation & upload flow screens
│   │   │   ├── create_video_screen.dart
│   │   │   ├── video_processing_screen.dart
│   │   │   └── video_publish_screen.dart
│   │   │
│   │   └── main_layout/           // NEW: Main layout screen that wraps content with the bottom nav bar
│   │       └── main_layout_screen.dart
│   │
│   ├── widgets/                   // Reusable UI components (stateless & stateful widgets)
│   │   ├── common/                // Generic widgets (buttons, text fields, etc.)
│   │   │   ├── custom_button.dart
│   │   │   └── custom_text_field.dart
│   │   │
│   │   ├── navigation/            // NEW: Navigation widgets (horizontal bottom nav bar)
│   │   │   ├── bottom_nav_bar.dart    // Main bottom navigation bar widget
│   │   │   └── nav_item.dart          // (Optional) Individual navigation item widget
│   │   │
│   │   ├── video/                 // Widgets specific to video rendering and interaction
│   │   │   ├── video_player_widget.dart  // Video player integration
│   │   │   ├── video_card_widget.dart    // Each TikTok-style video in the feed
│   │   │   ├── like_button.dart
│   │   │   ├── follow_button.dart
│   │   │   └── comment_section.dart
│   │   │
│   │   ├── metadata/              // Widgets to handle chess game metadata input & display
│   │   │   ├── metadata_form.dart         // Input form for ELO, date, etc.
│   │   │   ├── chess_tag_selector.dart    // Tag selector for chess openings
│   │   │   └── timestamp_editor.dart      // For adding phase timestamps
│   │   │
│   │   └── chess/                 // Specialized chess-related widgets
│   │       ├── move_annotation_panel.dart // Side panel with moves and annotations
│   │       ├── animation_overlay.dart     // Overlay animations for move classifications
│   │       └── pgn_export_widget.dart     // Button/form to export PGN data
│   │
│   ├── services/                  // Business logic, API calls, Firebase integrations
│   │   ├── auth_service.dart      // Firebase Auth integration
│   │   ├── storage_service.dart   // Firebase Storage integration
│   │   ├── database_service.dart  // Firestore/Realtime Database integration
│   │   └── functions_service.dart // Cloud Functions calls
│   │
│   ├── providers/                 // (Optional) State management (Provider, Riverpod, etc.)
│   │   ├── auth_provider.dart
│   │   ├── feed_provider.dart
│   │   └── video_provider.dart
│   │
│   └── utils/                     // Utility classes and constants
│       ├── constants.dart         // App-wide constants, e.g., theme colors, padding, etc.
│       ├── validators.dart        // Input validation functions
│       └── helpers.dart           // Helper functions (formatting, conversions, etc.)
│
└── pubspec.yaml                   // Project configuration and dependencies
```

### Notes on the structure:

Separation of concerns:
- Views: Represent full pages/screens.
- Widgets: Reusable UI components that can be composed into views.
- Models: Define the data structures for users, videos, and chess games.
- Services: Encapsulate Firebase operations and other business logic.
- Providers: (or another state management solution) to manage app state.

Scalability: The structure supports future features (e.g., detailed video analytics, chat features, etc.) by adding new folders under models, views, or services.

## 3. List of Key Widgets & Their Roles

Below is a breakdown of the widgets (or widget groups) that are essential for building the MVP:

### A. Landing & Authentication Widgets

**LandingScreen** (views/landing/landing_screen.dart):
- Role: Introduces the app, displays branding, and directs users to log in or sign up.

**LoginScreen** (views/auth/login_screen.dart) & **SignupScreen** (views/auth/signup_screen.dart):
- Role: Handle user authentication. Use custom_text_field.dart and custom_button.dart from widgets/common.

### B. Main Feed & Video Interaction Widgets

**MainFeedScreen** (views/feed/main_feed_screen.dart):
- Role: Displays a vertically scrollable feed of videos in TikTok style.

**VideoCardWidget** (widgets/video/video_card_widget.dart):
- Role: Represents an individual video post. Contains:
  - VideoPlayerWidget: For playing the video.
  - LikeButton, FollowButton, and CommentSection: Interactive buttons and panels.

**CommentSection** (widgets/video/comment_section.dart):
- Role: Displays comments and a form for new comments.

### C. Video Creation & Publishing Widgets

**VideoUploadScreen** (views/video_upload/video_upload_screen.dart):
- Role: Initiates the video upload process (choosing/recording video).

**VideoProcessingScreen** (views/video_upload/video_processing_screen.dart):
- Role: Shows the processing status, allowing creators to see progress.

**VideoPublishScreen** (views/video_upload/video_publish_screen.dart):
- Role: Collects additional metadata and confirms publishing.

### D. Chess Metadata & Editing Widgets

**MetadataForm** (widgets/metadata/metadata_form.dart):
- Role: Form for creators to input game metadata (ELO ratings, opponent details, date, site, result).

**ChessTagSelector** (widgets/metadata/chess_tag_selector.dart):
- Role: Allows tagging of videos by chess opening or other categories.

**TimestampEditor** (widgets/metadata/timestamp_editor.dart):
- Role: Enables adding timestamps to demarcate game phases (opening, middle, end).

### E. Specialized Chess Widgets

**MoveAnnotationPanel** (widgets/chess/move_annotation_panel.dart):
- Role: Displays a side panel with the complete list of moves and user annotations.

**AnimationOverlay** (widgets/chess/animation_overlay.dart):
- Role: Renders animations over the video to indicate move classifications (e.g., blunders, brilliant moves).

**PGNExportWidget** (widgets/chess/pgn_export_widget.dart):
- Role: Provides functionality to export the game in PGN format for download or sharing.

### F. Common / Utility Widgets

**CustomButton & CustomTextField** (widgets/common/):
- Role: Standardize look and feel across the app.

**Loading/Progress Indicators**:
- Role: Provide user feedback during video processing and network calls.

## 4. Firebase & Backend Integration

Each service in the /services folder will encapsulate specific Firebase functionalities:

- AuthService: Handles sign-in/sign-up, password recovery, and user session management.
- StorageService: Manages video file uploads and downloads.
- DatabaseService: Deals with Firestore/Realtime Database reads/writes for video metadata, likes, comments, and follow relationships.
- FunctionsService: Invokes Firebase Cloud Functions (for video processing tasks, notifications, etc.).

## 5. State Management & Data Flow

Depending on your preference (Provider, Riverpod, BLoC, etc.), the /providers folder manages the state:

- AuthProvider: Monitors authentication state changes.
- FeedProvider: Loads and caches video feed data.
- VideoProvider: Manages state for video upload and editing, including metadata, processing status, and publishing.

Each provider will interface with the corresponding service(s) to ensure a clean separation between UI and business logic.

## 6. Guidance for Cursor AI Agent Development

When guiding the Cursor AI agent (or any developer):

- Follow the File Structure: Create the directories as laid out above. This organization will help the agent locate models, views, widgets, and services quickly.
- Widget Modularity: Build small, reusable widgets (like buttons and forms) and then compose them into larger screens.
- Separation of Concerns: Keep the business logic (e.g., Firebase calls) in services/providers. Widgets should focus solely on presentation and minor state interactions.
- Naming Conventions: Use clear, descriptive names for files and classes (e.g., VideoCardWidget for video posts, MetadataForm for game metadata).
- Document & Comment: Ensure that each widget and service includes comments explaining its purpose, especially in complex areas like the video processing pipeline and chess-specific features.