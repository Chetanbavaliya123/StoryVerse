# StoryVerse 🎬✨
> **The Next-Generation Vertical Drama, Shorts, and AI Storytelling Platform.**

StoryVerse is a production-grade Flutter application delivering micro-dramas, episodic vertical shorts, interactive AI-generated fiction, and an immersive novel reading mode. Engineered with clean architecture, Riverpod 3 state management, Firebase backend services, and a custom design system.

---

## 🌟 Highlights & Key Features

### 1. Cinematic Episode Watching
- **Vertical Fullscreen Player**: Optimized 9:16 vertical playback with adaptive letterboxing and touch controls.
- **Autoplay & Next Episode Countdown**: Seamless 5-second countdown overlay with "Play Now", "Cancel", and persisted autoplay toggle.
- **Episode Quick-Switcher**: Bottom sheet selector with episode thumbnails, duration, lock states, and current chapter indicators.
- **Resume Watching Engine**: Real-time position tracking synced with Firestore `watchHistory`.

### 2. Fullscreen Shorts Feed
- **Preloading Pipeline**: 3-node sliding memory window ($N-1$, $N$, $N+1$) preventing scroll stutter and memory leaks.
- **Interactive Overlay**: Double-tap heart reactions, synchronized likes/bookmarks, sound mute persistence, and "Watch Now" deep navigation into full series.

### 3. Story Reader Mode (Novel / Script Mode)
- **Multi-Theme Support**: Dark Charcoal, OLED Pure Black, Sepia Vintage, Light Clean.
- **Customizable Typography**: 14–26pt font size adjustments, serif/sans typeface selection, and custom line height.
- **Read Aloud (TTS)**: Built-in reader with active sentence highlighting, speed controls (0.8x, 1.0x, 1.25x, 1.5x), and automated scrolling.

### 4. AI Story Generation Hub
- **Generative Story Studio**: Custom fiction generator across genres (Fantasy, Sci-Fi, Romance, Mystery, etc.).
- **Daily Quota Counter**: 3 free stories per day for standard accounts with live remaining count badge.
- **VIP Unlimited Access**: Unrestricted story generation for VIP members.

### 5. Monetization & Paywall Gating
- **Tiered Gating**: Episodes 1–3 are complimentary; Episode 4+ enforces VIP membership.
- **Rewarded Ad Session Unlock**: 5-second simulated rewarded sponsor ad unlocks individual episodes per session.
- **VIP Membership Portal**: Monthly and annual subscription management.

### 6. Design System & Theming
- **Tokenized Styles**: `StoryVerseThemeTokens` registered across `OLED Pure Black`, `Cinematic Charcoal`, and `Dark Crimson`.
- **Reusable Atoms**: `PrimaryButton`, `SecondaryButton`, `GenreChip`, `StoryCard` (Poster, Hero, Compact), and `AppBottomSheet`.
- **Haptic Feedback**: Integrated subtle tactile responses on navigation, button taps, and player actions.

### 7. Localization & Onboarding
- **5 Supported Languages**: English (`en`), Hindi (`hi`), Gujarati (`gu`), Marathi (`mr`), and Bengali (`bn`).
- **Interactive Onboarding**: 3-step first-launch setup capturing language and 3 favorite genres.

---

## 🏗️ Architecture & Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.12+ (Dart SDK ^3.12.2) |
| **State Management** | Flutter Riverpod 3 (NotifierProvider, StreamProvider, FutureProvider) |
| **Routing** | GoRouter 18 (StatefulShellRoute with deep linking support) |
| **Backend / Auth** | Firebase Auth, Cloud Firestore, Firebase Storage |
| **Media Player** | `video_player` with custom preloading and URL normalizer |
| **Design Tokens** | `ThemeExtension<StoryVerseThemeTokens>` + Google Fonts |
| **Deep Linking** | Custom scheme `storyverse://` & Universal Links `https://storyverse.app` |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.12.2 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK 34+ / Java 17+

### Installation
```bash
# Clone the repository
git clone https://github.com/Chetanbavaliya123/StoryVerse.git
cd StoryVerse/mobile

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze lib/ test/

# Run the test suite
flutter test
```

### Running Locally
```bash
# Start on connected Android device / emulator
flutter run
```

### Building Release APK
```bash
flutter build apk --release
```

---

## 🧪 Testing

StoryVerse includes unit and widget tests covering core business logic, models, and UI components:
```bash
flutter test test/design_system_and_widgets_test.dart
flutter test test/watching_experience_and_shorts_test.dart
```

---

## 📄 License & Attribution
Private proprietary project developed for the StoryVerse platform. All rights reserved.
