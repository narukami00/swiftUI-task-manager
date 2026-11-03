# TaskManager

Native SwiftUI iOS task manager with Firebase Authentication and Cloud Firestore.

## Specification
- iOS 17+, iPhone and iPad; system light/dark appearance and Dynamic Type.
- Email/password registration, sign-in, password reset, persistent session and sign-out.
- Personal live task list, All / Active / Done filters, title search.
- Add/edit title (1–120 characters), short description (0–500), toggle completion, confirm deletion.
- Tasks stored at `users/{uid}/tasks/{taskID}` with server timestamps.
- Ownership and field validation enforced in Firestore rules.
- Loading, empty, error and missing-configuration states.

## Implementation milestones
1. Repository and native Xcode project.
2. Firebase initialization and authentication.
3. Firestore task storage and rules.
4. SwiftUI task screens.
5. Setup guide and verification checklist.

The local Git repository is independent of GitHub. No remote is configured until you choose one.

## Get started

1. Follow [Firebase setup and Mac run instructions](docs/FIREBASE_SETUP.md).
2. Put your downloaded `GoogleService-Info.plist` into `FirebaseConfig/` (excluded from Git).
3. Publish `firestore.rules` in your Firebase project's Firestore Rules tab.
4. On a Mac with Xcode 16.3+, open `TaskManager.xcodeproj`, choose an iOS 17+ simulator and Run.

Firebase SDK 12.19.3 is pinned in the Xcode project. The iOS app needs no Node, Python, CocoaPods or XcodeGen. A local setup screen appears if Firebase configuration is missing or the bundle ID differs.

See [checks](docs/TESTING.md) and [actual validation status](docs/VALIDATION.md). This app has not yet been compiled or run in Xcode.

## Code map

- `TaskManagerApp.swift`: Firebase bootstrap and signed-in/signed-out routing.
- `AuthStore.swift`, `AuthView.swift`: email/password account flow.
- `TaskItem.swift`: task schema and input validation.
- `TaskStore.swift`: live Firestore reads and CRUD writes scoped to the UID.
- `TaskListView.swift`, `TaskEditorView.swift`: native task workspace.
- `firestore.rules`: backend ownership and schema enforcement.
- `scripts/generate_project.py`: optional maintainer tool for updating source membership in the checked-in Xcode project.
