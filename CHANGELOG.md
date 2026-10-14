# StoryVerse Changelog

All notable changes to the StoryVerse mobile platform are documented in this file.

---

## [1.0.0] - Production Release

### Milestone 1: Core Stabilizations ("Stop the Bleeding")
- **Edge-to-Edge Shorts Video Engine**:
  - Full viewport 9:16 vertical `PageView.builder` with `BoxFit.cover`.
  - Three-node sliding window preloader (preloads $N+1$, plays $N$, disposes $<N-1$).
  - Bottom seekbar scrub timeline with active time indicators.
  - Persistent audio mute state toggle across sessions.
- **Library Watch History**:
  - Replaced unconfirmed history clearance with destructive confirm dialog.
  - Added optimistic swipe-to-dismiss deletion with 4-second "Undo" snackbar.
- **Profile Enhancements**:
  - Pinned `SliverAppBar` with gradient backdrop and avatar header.
  - Fixed draggable modal sheet overflow by setting dynamic viewport sizing.
  - Integrated DiceBear procedural avatar generator and image upload support.

---

### Milestone 2: Backend & System Integration ("Make Everything Real")
- **Multi-Language Localization**:
  - Full localization support for English (`en`), Hindi (`hi`), Gujarati (`gu`), Marathi (`mr`), and Bengali (`bn`).
  - Real-time language switching with persistence to Firestore user documents.
- **Theming & Design Tokens**:
  - 3 curated themes: `OLED Pure Black`, `Cinematic Charcoal`, `Dark Crimson`.
  - Registered `StoryVerseThemeTokens` with custom typography, surfaces, and glow shadows.
- **Privacy & Compliance**:
  - Account deletion flow with re-authentication modal (email/password & Google credentials).
  - Cascade Firestore collection cleanups ensuring complete data removal.
- **Discovery**:
  - Multi-category genre filter chips.
  - Real unread notification count badge synced to user streams.

---

### Milestone 3: Premium UI & UX Overhaul
- **Curated Home Feed**:
  - 5-second auto-advancing Hero Carousel with touch-pause and indicators.
  - "Continue Watching" row with progress bars and exact time remaining.
  - "Because You Watched" dynamic genre-based recommendations.
  - Ranked #1–#10 Trending Now cards.
  - Browse by Language pills & Popular Genres.
  - AI Story Generator CTA banner.
- **First-Launch Onboarding**:
  - 3-step interactive setup: Welcome -> Language Selection -> Preferred Genres (pick 3).
  - Profile settings shortcut to re-run onboarding preferences at any time.
- **Micro-Interactions**:
  - Pull-to-refresh on Home and all 4 Library tabs.
  - Haptic feedback on bottom navigation, buttons, and switches.
  - Shimmer image loaders with initials-based gradient fallback on dead links.

---

### Milestone 4: Retention, Monetization & Value
- **Paywall & Monetization Gating**:
  - Free access to Episodes 1–3 for all catalog stories.
  - Gated Episode 4+ with VIP membership paywall.
  - "Watch Ad to Unlock" mechanism with 5-second simulated rewarded countdown.
  - Session unlock state provider (`unlockedEpisodesProvider`).
- **Cinematic Video Watching**:
  - Autoplay toggle switch in episode controls.
  - 5-second next-episode countdown overlay with circular timer, "Play Now", and "Cancel".
  - Pre-advance paywall check preventing accidental play of locked episodes.
- **Story Reader Mode**:
  - `StoryReaderScreen` with 4 reading themes: Dark, Black, Sepia, Light.
  - Typography controls: 14–26pt font size slider, serif/sans toggle.
  - Reading progress bar with debounced Firestore sync.
  - Simulated TTS / Read Aloud playback bar with sentence highlighting, auto-scroll, and speed control (0.8x, 1.0x, 1.25x, 1.5x).
  - Chapter navigation drawer.
- **AI Story Generator Quota**:
  - Daily limit of 3 free stories for standard users.
  - Live quota counter badge in AI Hub.
  - Direct upgrade pathway to VIP for unlimited generations.
- **Deep Linking Support**:
  - Intent filters for `storyverse://` custom scheme and `https://storyverse.app`.
  - Deep link routing for stories, player, shorts, and reader.

---

### Milestone 5: Quality & Release Readiness
- **Test Suite**:
  - 28 unit and widget tests covering models, design system, buttons, cards, player controls, and quota state.
  - 100% clean analyzer output (`0 issues found`).
- **Release Verification**:
  - Production Android release build validated.
  - Cleaned repository of legacy mock/demo catalog files.
- **Documentation**:
  - Comprehensive `README.md`, `DECISIONS.md`, and `CHANGELOG.md`.
