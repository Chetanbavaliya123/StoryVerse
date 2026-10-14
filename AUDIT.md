# StoryVerse — Architecture & Codebase Audit (Top 15 Issues)
**Date:** October 2026  
**Auditor:** Principal Flutter Engineer  

### Executive Summary
StoryVerse has a strong visual foundation and great core ideas (episodic micro-video player, AI stories, multi-language support). However, the implementation had junior anti-patterns: mock data leaks, UI overflows, duplicate controls, missing safety guards, and inconsistent state synchronization.

---

### Top 15 Architectural & Codebase Problems

1. **Language & Region Bottom Sheet Overflow:** The sheet exceeded vertical screen bounds by 235px on standard devices due to an unconstrained, non-scrollable `Column` inside an unexpanded bottom sheet.
2. **Shorts Video Engine Inefficiencies:** Feed lacked next-video preloading, controller lifecycle hygiene, mute state persistence across app sessions, and contained UI typos ("Shart" in logging/feedback).
3. **Floating AI Button (FAB) Duplication & Overlap:** A floating action button was anchored on `HomeScreen`, overlapping carousel cards and duplicating the dedicated AI Hub card and navigation tab.
4. **Bottom Nav Clipping:** Scrollable lists and grids across Home, Library, and Discover lacked adequate bottom safe insets (`EdgeInsets.only(bottom: 100+)`), leaving trailing items inaccessible beneath the bottom navigation bar.
5. **Hero Carousel Glitches:** The Hero Card duplicated genre tags (e.g. `SCI-FI • SCI-FI`) and truncated critical Gujarati and Hindi story titles to a single line with ellipses instead of allowing 2 lines.
6. **Profile Screen Status Bar Collisions:** Profile screen lacked `SliverAppBar` with pinned elevation or top-safe area pinning, causing user avatars and stats to clip into the system status bar upon scrolling.
7. **Premium State Inconsistency:** Displayed a "Premium Member" gold badge while the Premium page was labeled "Coming Soon" with no real billing pipeline, creating user confusion.
8. **Library Watch History Static Timestamps:** The history view displayed hardcoded strings like "Last watched recently" rather than actual Firestore timestamps and progress bar ratios, lacked confirmation for "Clear History", and lacked an Undo action on deletion.
9. **Edit Profile Anti-patterns:** Did not prefill the user's current display name, asked users for a raw "Custom Photo URL" string instead of providing illustrated avatar presets or native image selection, and used generic photo assets.
10. **Category Tabs & Filter Desynchronization:** Category tabs (Popular, Trending, New, Romance, Horror, Comedy) on Home were disconnected from state-driven filtered streams.
11. **Search & Discovery Limitations:** Search did not debounce queries, lacked voice search integration, and lacked empty-state query suggestions.
12. **Notification Bell Disconnected:** The header notification bell was a dead icon with a static unread badge rather than a live stream of user notifications.
13. **Account Deletion Compliance (Google Play):** Missing mandatory self-service Account Deletion with re-authentication and cascading deletion of user history, bookmarks, and preferences.
14. **Lack of Centralized Design System Tokens:** Colors and font styles were defined across ad-hoc constants and inline styles rather than a unified `DesignTokens` / `ThemeExtension` system with real multi-theme support (OLED Pure Black, Cinematic Charcoal, Dark Crimson).
15. **Localization Incompleteness:** App language selection changed local state without full `flutter_localizations` string catalogs for Hindi, Gujarati, Marathi, and Bengali.

---

### Immediate Action Plan
Proceeding immediately with **Milestone 1 (Stop the Bleeding)** to resolve all critical UI bugs, followed by **Milestones 2 through 5** for end-to-end backend wiring, design system unification, product retention features, and release certification.
