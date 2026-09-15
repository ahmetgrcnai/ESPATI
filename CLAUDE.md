# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Espati — a Flutter social app for pet owners (Türkçe UI/comments throughout; Eskişehir-focused location features) to connect, share posts/stories/"Paties" (short videos), find pet-friendly places on a map, and chat with a Gemini-backed AI vet assistant ("Pati AI").

## Commands

```bash
flutter pub get              # install dependencies
flutter run                  # run on a connected device/emulator
flutter analyze              # static analysis (flutter_lints, see analysis_options.yaml)
flutter test                 # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk|ios        # release builds
flutterfire configure        # regenerate lib/firebase_options.dart after Firebase project changes
```

A `.env` file (copy from `.env.example`, never commit it) must exist before `flutter run` — `main.dart` calls `dotenv.load()` before Firebase/AI services construct. Relevant keys: `VISION_API_KEY` (SafeSearch moderation), `PATI_BACKEND_URL` / `PATI_BACKEND_API_KEY` (Pati AI chat backend). `ANTHROPIC_API_KEY`/`GEMINI_API_KEY` are legacy/unused leftovers from earlier AI-provider migrations.

## Architecture

**Layering:** `screens/` (UI) → `viewmodels/` (`ChangeNotifier`, MVVM) → `data/repositories/interfaces/` (abstract contracts) → concrete `data/repositories/firebase/*` or `data/repositories/mock/*` implementations. Screens never touch a concrete repository or Firestore/Storage API directly — they read a `ViewModel` via `provider`, and a `ViewModel` only depends on the `I*Repository` interface injected into it.

**Dependency wiring lives entirely in `lib/core/service_locator.dart`.** Every repository and viewmodel is registered there via `MultiProvider`. The single line `const bool kUseMock` at the top of that file switches the *entire app* between offline mock repositories (works with no backend, login `test@espati.com` / `password123`) and live Firebase repositories — no other code changes when toggling it. When adding a new feature that needs a repository, add both a `Mock*Repository` and `Firestore*Repository` implementing the same `I*Repository` interface, then register both behind `kUseMock` in `service_locator.dart`.

**Result type:** repository methods return `Result<T>` (`lib/core/result.dart`, a sealed `Success`/`Failure` type) rather than throwing, so viewmodels/UI must exhaustively handle both cases via pattern matching.

**Firebase init order matters:** `main.dart` loads `.env` → initializes `Firebase.initializeApp` → initializes `NotificationService` — before `runApp`. `AuthViewModel` is registered first among providers in `service_locator.dart` because it subscribes to `authStateChanges` immediately, and other viewmodels/screens assume auth state is already available.

**AI vet assistant:** `IAIService` (`lib/core/i_ai_service.dart`) is the abstract contract; `PatiAiService` (`lib/services/pati_ai_service.dart`, accessed as a singleton `PatiAiService.instance`) is the concrete implementation, calling an external `pati_ai_backend` (Gemini + PDF-grounded RAG) `/chat` endpoint over HTTP. If `PATI_BACKEND_URL` is unset, it falls back to local mock responses. Every request sends full `ChatMessage` history for multi-turn context; image-analysis requests compress the image client-side before base64 encoding.

**Design system:** UI follows a custom "Neo-Brutalist" design language — shared tokens/widgets in `lib/core/neo_brutalism.dart`, `lib/core/neo_brutalist_tokens.dart`, and `lib/widgets/common/neo_brutalist_*.dart`. Prefer these shared widgets over ad-hoc styling when building new screens.

**Firestore security & indexes:** rules live at repo root in `firestore.rules` / `storage.rules` (referenced from `firebase.json`), not inside `lib/` — check these when a feature needs new read/write access patterns or collections.
