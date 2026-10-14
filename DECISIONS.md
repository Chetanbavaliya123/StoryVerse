# StoryVerse — Engineering & Design Decisions
**Author:** Principal Flutter Engineer  
**Status:** Living Document  

This document logs all production-grade architectural, security, and UX decisions made throughout the StoryVerse transformation.

---

### Decision Log

#### D-001: Bottom Sheet Architecture
- **Issue:** Language & Region and other modal sheets overflowed on smaller screens.
- **Decision:** Use `isScrollControlled: true` along with `DraggableScrollableSheet` with a defined `initialChildSize: 0.65`, `minChildSize: 0.4`, and `maxChildSize: 0.9` with `SingleChildScrollView` / `ListView` so that keyboard appearances and various DPIs never trigger render overflows.

#### D-002: Navigation & Floating Controls
- **Issue:** Floating AI button on `HomeScreen` overlapped bottom horizontal story lists and duplicated the dedicated AI Hub card and navigation tab.
- **Decision:** Remove the FAB completely from `HomeScreen`. Retain the AI Hub card in the main feed and keep the dedicated `/ai` tab in the bottom navigation for clean access without screen clutter.

#### D-003: Video Engine Preloading & Lifecycle Hygiene
- **Issue:** Shorts vertical feed lagged on fast scrolls and leaked controller resources.
- **Decision:** Implement a three-node window: Preload index $N+1$, play index $N$, dispose index $< N-1$. Store mute preference in shared preferences/repository so user's choice persists across screen switches.

#### D-004: Premium Status Source of Truth
- **Issue:** Mock gold "Premium Member" badge was displayed even when billing was unintegrated ("Coming Soon").
- **Decision:** Bind premium status to a central provider (`isPremiumUserProvider`) which checks Firestore `users/{uid}.isPremium`. If false/unsubscribed, do not show misleading "Premium Member" badge; instead display "Free Plan" with an upgrade flow or VIP waitlist dialog.

#### D-005: Library Watch History & Undo Safety
- **Issue:** Clear History previously wiped all items without a confirmation modal or snackbar recovery.
- **Decision:** Introduce a modal confirm dialog before destructive Clear History. For individual item dismissals, implement optimistic removal with a 4-second "Undo" snackbar.

#### D-006: User Data Isolation
- **Issue:** Logging out and switching accounts could leak previous cached user state.
- **Decision:** All user-specific streams (`watchHistoryStoriesProvider`, `favoriteStoriesProvider`, `libraryStoriesProvider`, `currentUserProfileProvider`) strictly listen to `authStateChangesProvider`. Upon sign out, all user providers emit empty/null states and Firestore local cache is isolated per UID.

#### D-007: AppThemeTokens via ThemeExtension
- **Issue:** Hardcoded ad-hoc hex values across screens resulted in fragmented dark styling and poor reusability.
- **Decision:** Built `StoryVerseThemeTokens extends ThemeExtension<StoryVerseThemeTokens>` housing all semantic colors (`primaryBackground`, `surface`, `surfaceElevated`, `accent`, `border`, `textPrimary`, `textSecondary`, `textMuted`), border radii (`radiusSm`, `radiusMd`, `radiusLg`), and curated shadow effects. Registered across all 3 themes (`OLED Pure Black`, `Cinematic Charcoal`, `Dark Crimson`).

#### D-008: Multi-Language & Region Localization
- **Issue:** App content was hardcoded in English with non-functional language picker.
- **Decision:** Implemented `AppLocalizations` supporting 5 languages (`en`, `hi`, `gu`, `mr`, `bn`) with fallback mechanisms and a reactive `appLocaleProvider`. User selection persists to Firestore user document preferences.

#### D-009: Strict Account Deletion & Play Store Compliance
- **Issue:** Account deletion lacked re-authentication and cascade deletion, violating Google Play developer policies.
- **Decision:** Added credential re-authentication dialog (handling both email/password and Google provider tokens), cascading document deletion across Firestore collections (`watchHistory`, `favorites`, `library`, `comments`, `userProfile`), and final Firebase Auth user deletion.

#### D-010: Curated Home Feed Hierarchy
- **Issue:** Home feed was disorganized with static carousels and no recommendation engine.
- **Decision:** Established an 8-tier visual hierarchy:
  1. Hero Carousel (5s auto-advance with touch-pause and animated indicators)
  2. Continue Watching (progress bar + exact formatted time remaining)
  3. "Because You Watched [Title]" (dynamic recommendations matching user's last watched genre)
  4. Trending Now (#1–#10 ranked badges)
  5. New Arrivals
  6. Browse by Language (Hindi, English, Gujarati, Marathi, Bengali chips)
  7. Popular Genres
  8. AI Story Generator Hub CTA Card

#### D-011: First-Launch Onboarding Gate
- **Issue:** New users landed directly on Home with no personalization or preference discovery.
- **Decision:** Implemented a 3-step interactive onboarding flow: Welcome -> Language Preference -> Preferred Genres Selection (minimum 3). Persists choices directly to user profile in Firestore and syncs active locale.

#### D-012: Paywall Gating & Rewarded Unlock Mechanism
- **Issue:** All episodes were accessible without premium monetization or revenue generation.
- **Decision:** Enforced Episode 1–3 complimentary access. Episode 4+ requires VIP membership or a 5-second simulated sponsor rewarded ad unlock via `PaywallBottomSheet` with session unlock tracking in `unlockedEpisodesProvider`.

#### D-013: Next-Episode Autoplay & Countdown
- **Issue:** Episode player abruptly stopped or auto-jumped without giving users notice or choice.
- **Decision:** Added toggleable autoplay with a 5-second countdown overlay featuring circular timer progress, next episode metadata, "Play Now", and "Cancel". Enforces paywall gating prior to auto-advancing.

#### D-014: Story Reading Mode with Typography & Text-To-Speech
- **Issue:** Text stories and scripts were treated as basic descriptions without a dedicated reader.
- **Decision:** Built `StoryReaderScreen` offering:
  - 4 reading themes: Dark Charcoal, OLED Pure Black, Sepia Vintage, Light Clean
  - Typography controls: 14–26pt font size slider, serif/sans typeface toggle
  - Reading progress bar with debounced Firestore/local sync
  - Text-to-speech / Read Aloud playback bar with sentence highlighting, auto-scroll, and speed control (0.8x, 1.0x, 1.25x, 1.5x)
  - Chapter navigation drawer

#### D-015: AI Story Generator Daily Free Quota
- **Issue:** AI story generation was unconstrained and could abuse generative backend quotas.
- **Decision:** Created `AiQuotaNotifier` limiting free tier users to 3 generations per day. Displays a live remaining quota badge in the AI Hub with direct VIP upgrade prompts for unlimited access.
