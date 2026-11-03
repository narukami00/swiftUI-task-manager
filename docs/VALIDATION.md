# Validation record — 4 November 2026

## Passed on Windows

- `python scripts/verify_project.py`: deterministic Xcode project generation, all seven Swift files included, unique and resolved project object references, valid shared scheme XML and backend JSON, Firebase plist excluded from Git.
- `node --check tests/firestore.rules.test.mjs`: test runner syntax check.
- `npm run test:rules`: local Firestore Standard emulator 1.22.0, one test containing 29 REST operation assertions, zero failures. Checks cover owner create/read/list/edit/complete/reopen/delete; denied anonymous and other-user access; rejected empty/whitespace titles, excessive lengths, missing/extra fields, wrong types, initially completed tasks and changed creation timestamps; accepted boundary lengths, emoji and multiline titles.
- The emoji boundary check exposed Firestore emulator limits in UTF-16 units. Swift validation and visible counters were corrected to use `.utf16.count` (60 two-unit emoji fit the 120-unit title limit; 61 do not).
- Emulator shut down after execution. Port 8187 is configured to avoid an existing service using 8080. No production Firebase project was contacted by these rules tests.

## Not yet verified

- Swift compilation, package resolution and native project import in Xcode. Neither Xcode nor an iOS SDK is installed on this Windows host.
- Simulator/device UI, session restoration and live Firebase email/password authentication.
- Physical-device signing and distribution.

Follow `FIREBASE_SETUP.md` on a Mac to complete these checks. The app source is implemented; end-to-end verification is pending.

## Live Firebase configuration follow-up

- Validated the supplied local `FirebaseConfig/GoogleService-Info.plist`: project `swiftytask-9cf50`, bundle ID `com.rafsan.TaskManager`, and required client identifiers present. The file remains excluded from Git and is already included by the Xcode resource folder.
- Confirmed the live `(default)` database is Standard edition / Firestore Native.
- Read the live Authentication configuration: email sign-in enabled and password required.
- Successfully deployed `firestore.rules` and `firestore.indexes.json` to `swiftytask-9cf50` using the signed-in Firebase CLI. Firebase compiled and released the rules successfully.
- Added `.firebaserc` so future CLI operations default to this project. Emulator tests still explicitly target `demo-task-manager`.
- No live user accounts or task documents were created. Actual iOS sign-in and task operations still need the Xcode first-run checklist.

## Tooling note

Firebase CLI 15.34.2 is pinned as a development-only dependency. Its npm audit reports 16 moderate findings (zero high/critical), including transitive dependencies. No forced dependency downgrade was applied. Node packages are used only to run local backend checks and are not bundled into the Swift iOS application.
