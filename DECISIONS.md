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
