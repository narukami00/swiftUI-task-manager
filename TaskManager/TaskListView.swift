import SwiftUI

// Replaced by the task workspace in the next milestone.
struct TaskListView: View {
    let userID: String
    let email: String
    @EnvironmentObject private var session: AuthStore
    @State private var error: String?
    var body: some View {
        NavigationStack {
            VStack {
                Text("Signed in as \(email)")
                Button("Sign out") {
                    do { try session.signOut() } catch { self.error = error.localizedDescription }
                }
                if let error { Text(error) }
            }.navigationTitle("My tasks")
        }
    }
}
