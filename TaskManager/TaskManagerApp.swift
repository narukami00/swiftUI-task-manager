import SwiftUI

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentUnavailableView("TaskManager", systemImage: "checkmark.circle", description: Text("Your tasks, in one place."))
        }
    }
}
