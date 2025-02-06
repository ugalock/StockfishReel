# StockfishReel

A TikTok-style chess video sharing app where chess streamers can upload and share their game analyses.

## Features

- TikTok-style vertical scrolling video feed
- Video categorization by chess openings
- Game metadata including ELO ratings and results
- Interactive features (likes, comments, follows)
- Timestamp markers for game phases (opening, middlegame, endgame)
- Move annotations and classifications
- PGN export functionality

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase project with the following services enabled:
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Firebase Functions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/stockfishreel.git
cd stockfishreel
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add your Android and iOS apps to the project
   - Download and add the configuration files:
     - Android: `google-services.json` to `android/app/`
     - iOS: `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/          # Data models
├── services/        # Firebase and other services
├── views/           # Screen-level widgets
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
