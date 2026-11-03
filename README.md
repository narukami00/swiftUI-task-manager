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
