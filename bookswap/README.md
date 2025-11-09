# BookSwap

BookSwap is a Flutter mobile app (Android/iOS) that lets students list textbooks to swap, make swap offers, and chat with other students. The app uses Firebase for Authentication and Cloud Firestore for real-time data storage. This repository contains the full source code for the app used in the Individual Assignment 2.

---

## Table of contents
- Project overview
- Features
- Project structure
- Prerequisites
- Firebase setup (Auth / Firestore / Storage)
- Running the app (emulator / device)
- Common troubleshooting & fixes
- Developer workflow and commands
- Demo checklist (what to show in video)
- Contribution & license

---

## Project overview
This app demonstrates a small marketplace where students can:
- Post book listings (title, author, condition, image)
- Browse listings
- Initiate swap offers (pending/accepted/rejected lifecycle)
- Chat with other users (per chat messages stored in Firestore)

State management: Provider (ChangeNotifier) is used (`AuthProvider`, `BooksProvider`, `SwapProvider`).

Firestore usage (high level):
- `books` collection — documents for listings
- `users` collection — profiles
- `chats` collection — chat meta and `messages` subcollections
- `userReadStatus/{userId}/chats/{chatId}` — per-user unread counters (badges)

---

## Features
- Firebase Authentication (email/password) with sign up / sign in / sign out.
- CRUD on books: create, read (browse), update, delete (owner-only).
- Swap flow: initiate swap -> book status becomes `pending` and appears in My Offers. Owner can accept/reject.
- Chat: two-user chats with message storage and unread badges.
- Notification badges in UI (unread messages and pending-offer badges).

---

## Project structure
```
bookswap/
  android/ ios/ web/ macos/ windows/ linux/
  lib/
    models/        # Book and User models
    providers/     # Providers for Auth, Books, Swap
    screens/       # UI screens: browse, post, my_listings, chats, settings
    services/      # FirestoreService, StorageService
    widgets/       # Reusable widgets (BookCard, etc.)
    main.dart
  test/
  pubspec.yaml
  firebase.json
  .gitignore
  README.md
```

---

## Prerequisites
- Flutter SDK (stable) installed: https://flutter.dev/docs/get-started/install
- Android Studio or VS Code with Flutter plugin
- Firebase CLI (optional, for deploying rules/indexes):
  ```bash
  npm install -g firebase-tools
  firebase login
  ```

---

## Firebase setup
1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication → Sign-in methods → Email/Password (required)
3. Create Firestore database (test mode while developing, then tighten rules)
4. (Optional) Enable Firebase Storage if you want to store images there. The app supports a data-URL fallback when Storage isn't available.
5. Download and place platform config files if you plan to run on devices/emulators:
   - Android: `android/app/google-services.json` (DO NOT commit this to source)
   - iOS: `ios/Runner/GoogleService-Info.plist` (DO NOT commit this)

---

## Running the app
1. Get dependencies:
   ```bash
   flutter pub get
   ```
2. For a full clean & run (recommended if you see DDC/module errors):
   ```bash
   flutter clean
   flutter pub get
   flutter run -d <device-id>
   ```
3. To analyze the project:
   ```bash
   flutter analyze
   ```

---

## Firestore indexes & common backend fixes
- If you see a Firestore error saying a composite index is required (e.g. `failed-precondition: The query requires an index`), open the console link shown in the error and create the suggested index. You can also add an indexes JSON and deploy with `firebase deploy --only firestore:indexes`.

## Common troubleshooting
- Image on web: `Image.file` is not supported on web — use `XFile` bytes, `Image.memory` or upload to Storage and use a URL.
- DDC/DevService hot-reload error: circular imports can cause DDC module redefinition errors. If you see "Failed to start Dart Development Service" or similar, stop the app and run a full restart:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d <device>
  ```

---

## Demo checklist (what to show in video)
- Sign up, verify email, sign in/out (show Firebase console)
- Post a book (show Firestore document created)
- Edit and delete listings (Firestore reflected)
- Make swap offer, accept/reject (Firestore reflected)
- Chat messages and unread badge behavior (Firestore reflected)
- Show Dart Analyzer output

---

## Contribution & license
If you want to contribute, fork and submit pull requests. This repo is for the Individual Assignment 2 submission; do not publish secrets.

---

If you'd like I can expand this README with: sample `.firestore.indexes.json` entries, exact firebase rules snippets, and short developer notes on how to test using the Firestore emulator. Ask and I will add them.
# bookswap

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
