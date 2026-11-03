# Local checks

## Repository / project checks (Python 3, Windows or macOS)

```sh
python scripts/verify_project.py
```

## Backend rules checks (Node 22+, Java 21+)

```sh
npm ci --ignore-scripts
npm run test:rules
```

The runner starts and stops only a local Firestore emulator using `demo-task-manager`. It needs network access to download the emulator on its first run. No Firebase login or production configuration is required. The test refuses a non-local endpoint. Node tooling is solely for backend development checks; it is not an iOS app dependency.

On a Mac, list simulator names with `xcrun simctl list devices available`, then compile using an installed destination:

```sh
xcodebuild -project TaskManager.xcodeproj -scheme TaskManager -destination 'platform=iOS Simulator,name=YOUR_INSTALLED_IPHONE_SIMULATOR' -derivedDataPath DerivedData build CODE_SIGNING_ALLOWED=NO
```

Use the first-run acceptance checklist in `FIREBASE_SETUP.md` to validate the live app. There is no automated XCTest target and no iOS runtime test has been performed on Windows.
