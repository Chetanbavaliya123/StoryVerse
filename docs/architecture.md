# StoryVerse Architecture

## Project Overview
StoryVerse is a short-video storytelling platform comprising two main applications:
1. **StoryVerse Mobile App (Flutter)**: A user-facing app for discovering and watching stories, viewing AI-generated content, and managing a personal library.
2. **StoryVerse Admin Web Panel (React)**: A secure web application for administrators to moderate content, manage users, and review AI-generated stories before publishing.

## Mobile Application (Flutter)
- **Framework**: Flutter (Android-first, iOS supported).
- **State Management**: Riverpod.
- **Routing**: GoRouter.
- **Visual Design**: Strict adherence to the Google Stitch Design System (Dark cinematic theme).
- **Architecture**: Feature-based architecture (`lib/core`, `lib/features`, `lib/firebase`).

## Admin Web Panel (React)
- **Framework**: React.js (via Vite) + TypeScript.
- **Styling**: Tailored to match the Stitch Admin visual reference.
- **Architecture**: Component-based modern React structure, connected directly to Firebase Web SDK.

## Backend (Firebase)
- **Database**: Cloud Firestore. NoSQL structure utilizing top-level collections (`users`, `stories`, etc.) and `episodes` as subcollections.
- **Authentication**: Firebase Auth (Email/Password, Google Sign-In) combined with Firestore-based Role-Based Access Control (RBAC).
- **Storage**: Firebase Storage for media assets.
- **Cloud Functions**: For secure AI API integrations and elevated admin tasks.
- **Security**: Strict Firebase Security Rules to block client-side circumvention of admin permissions.
