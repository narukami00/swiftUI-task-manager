# Firebase setup and first Mac run

## 1. Create the Firebase backend now

1. Open [Firebase Console](https://console.firebase.google.com/) and create/select a project. Analytics is optional; this app does not use it.
2. In Project overview, add an **iOS / Apple app**.
3. Enter the case-sensitive bundle ID **com.rafsan.TaskManager**. Nickname: TaskManager. An App Store ID is unnecessary for this development run.
4. Download **GoogleService-Info.plist**. Keep its exact filename. Copy it into the repository's **FirebaseConfig** folder, beside `.gitkeep`. This folder is already included as a resource folder in the Xcode project. Do not add a second copy through Xcode.
5. Skip Firebase's manual SDK / initialization snippets: this repository already includes FirebaseCore, FirebaseAuth and FirebaseFirestore through Swift Package Manager and configures Firebase in the app delegate.
6. In **Build → Authentication → Get started → Sign-in method**, enable **Email/Password** and Save. Email link sign-in is unnecessary. Registration in the app creates Firebase users automatically.
7. In **Build → Firestore Database → Create database**, choose **Standard edition**, the **(default)** database, and **production mode**. Pick a suitable region before creating it.
8. Open Firestore's **Rules** tab, replace the rules with the complete contents of `firestore.rules` in this repository, and click **Publish**. Keep these rules; do not switch to open test-mode rules.
9. No collections or indexes need to be created manually. Saving your first task creates `users/{uid}/tasks/{taskID}`. The parent `users/{uid}` document itself is not written; the console may display a placeholder parent.

Official references: [Apple setup](https://firebase.google.com/docs/ios/setup), [email/password auth](https://firebase.google.com/docs/auth/ios/password-auth), [Firestore creation](https://firebase.google.com/docs/firestore/quickstart), [access rules](https://firebase.google.com/docs/firestore/security/rules-conditions).

## 2. What to send back

- Your Firebase **project ID** (Project settings → General).
- Confirmation that Email/Password is enabled, the default Firestore database exists, and rules were published.
- Confirm the plist is at `FirebaseConfig/GoogleService-Info.plist`. You may attach that client configuration if you want its identifiers checked, but local placement is sufficient.
- If you want a different bundle identifier, say so before registering the Apple app; it must match both Xcode and the plist.

Do not share Firebase passwords, Apple account passwords, service-account JSON files, private keys or signing certificates. The downloaded Apple plist contains client project identifiers, not administrator credentials. It is excluded from Git here so you can transfer it separately as requested. Firestore rules protect data; keeping the plist out of Git is not an access-control mechanism.

## 3. Transfer the repository

All milestones are committed locally. To use GitHub/GitLab, create an empty repository in your own account, then run the following from this folder, replacing the example URL:

```sh
git remote add origin https://github.com/YOUR-ACCOUNT/TaskManager.git
git push -u origin main
```

On your friend's Mac, clone the repository. Transfer `GoogleService-Info.plist` separately and put it in `FirebaseConfig`. Do not transfer `node_modules` or build folders.

## 4. Open and run on a Mac

1. Use an Apple silicon Mac with **Xcode 16.3 or newer** and an iOS 17+ simulator runtime. The project builds for ARM64 and pins **Firebase 12.19.3**, whose package manifest requires Swift 6.1.
2. Double-click **TaskManager.xcodeproj**. This is a native project, not a Swift Playground. No CocoaPods, XcodeGen, Python or Node installation is needed to run the app.
3. Wait for Xcode to resolve Swift packages. Internet is required on first open. The checked-in `Package.resolved` records the versions resolved during the Mac run.
4. Select scheme **TaskManager** and an **iPhone simulator** running iOS 17 or later.
5. Press **Run** (Command-R). A simulator does not require selecting a personal development team.
6. For a physical iPhone, select the app target → **Signing & Capabilities** → select your own Team, enable automatic signing, select the connected device, and run. If signing requires a different bundle ID, register that ID as another Apple app in Firebase and download its matching plist. Keep the ID in `scripts/generate_project.py` consistent if you use that maintenance script later.
7. If you see “Firebase setup needed”, check the plist location, exact filename, bundle ID, then rebuild. The blue FirebaseConfig resource folder copies the file into the app; no manual target membership change is needed.

Only email/password Auth and Firestore are used. No APNs keys, push entitlement, Google sign-in URL scheme, server deployment or service-account file is needed.

## 5. First-run acceptance checklist

- Launch without a plist once: setup instructions appear instead of an authentication screen.
- Restore the plist and rebuild. Register an email/password account. Confirm it appears in Firebase Authentication.
- Add a task with title and description. Confirm its document appears under your UID in Firestore, with `createdAt` and `updatedAt` timestamps.
- Edit both fields, complete the task, switch Active/Done filters, mark active again, and search by title/description.
- Cancel editing after changing text: confirm discard. Try a blank title and over-limit fields: Save is disabled.
- Delete a task: cancel first, then confirm; verify the document disappears.
- Force quit/reopen: session restores and tasks load. Sign out and sign back in: tasks remain.
- Register another account: the first account's tasks must not appear. Sign back into the first account to verify its data remains.
- Use password reset with an existing account; check inbox/spam and verify the new password.
- Test large text sizes, light/dark appearance, an iPad layout and VoiceOver labels.
- Disconnect the network: reads may show cached data; writes display a pending message until internet returns and the server acknowledges them. This first version is online-first, not a complete offline editing workflow. Do not uninstall or force quit while waiting for a write if you need immediate confirmation.
- Reject a write temporarily with restrictive rules in a separate development project, restore rules and retry; the editor should preserve the unsaved draft and show an error.

## 6. Troubleshooting

| Symptom | Check |
|---|---|
| Authentication operation not allowed | Enable Email/Password in the matching Firebase project. |
| Missing or insufficient permissions | Publish repository rules in the same project's default Firestore database; sign in again. |
| Database not found | Create the `(default)` Standard Firestore database. |
| API key / project error | Use the plist downloaded for this exact Apple app and project; check any manually applied API restrictions. |
| Package requires newer Swift | Use Xcode 16.3+ for the pinned SDK; confirm command-line tools point at that Xcode if using terminal builds. |
| Save keeps waiting | Restore network access. Firestore write completion waits for backend acknowledgment. |
| Unsupported task format | Check task fields match the schema. Avoid manually creating malformed documents in the console. |

## 7. Architecture and deliberate scope

SwiftUI views → Firebase Authentication session → `TaskStore` → Firestore client SDK → Firestore security rules → per-user task documents. Firebase provides the hosted backend; no custom API server is needed.

Each task has `title` (1–120 UTF-16 units; some emoji use two units), `notes` (0–500 UTF-16 units), `isDone` (Boolean), `createdAt` and `updatedAt` (server timestamps). Editing preserves `createdAt`. New tasks start active. The current version uses last-write-wins when two devices edit the same fields. The list loads the account's task collection without pagination, appropriate for a basic personal task manager.

The app uses native SwiftUI controls, system colors, Dynamic Type and labeled buttons. It includes no analytics, social login, due dates, reminders or collaboration. Account deletion and an App Store release package are not implemented; this deliverable is for development/simulator/device use. Add account deletion and finish distribution requirements before an App Store submission.

## 8. Verification status

See `VALIDATION.md` for the Windows checks and the reported Mac run. Use the acceptance checklist to verify your own Firebase and Xcode setup.
