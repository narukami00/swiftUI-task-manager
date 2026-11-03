import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var configurationError: String?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist", inDirectory: "FirebaseConfig"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            Self.configurationError = "Place GoogleService-Info.plist in FirebaseConfig, then rebuild the app in Xcode."
            return true
        }
        guard options.bundleID == Bundle.main.bundleIdentifier else {
            Self.configurationError = "The Firebase configuration bundle ID must match the app's bundle identifier in Xcode."
            return true
        }
        FirebaseApp.configure(options: options)
        return true
    }
}

@main
struct TaskManagerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            // Firebase-dependent state is created only after Firebase is configured.
            if FirebaseApp.app() != nil {
                SessionView().tint(.indigo)
            } else {
                ContentUnavailableView("Firebase setup needed", systemImage: "gearshape.2",
                    description: Text(AppDelegate.configurationError ?? "Configure Firebase and rebuild the app."))
            }
        }
    }
}

struct SessionView: View {
    @StateObject private var session = AuthStore()

    var body: some View {
        Group {
            if session.isRestoringSession {
                ProgressView("Opening your workspace…")
            } else if let user = session.user {
                TaskListView(userID: user.uid, email: user.email ?? "Your account").id(user.uid)
            } else {
                AuthView()
            }
        }
        .environmentObject(session)
    }
}
