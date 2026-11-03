import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isRestoringSession = true
    @Published private(set) var isBusy = false
    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.user = user
                self?.isRestoringSession = false
            }
        }
    }

    deinit {
        if let listener { Auth.auth().removeStateDidChangeListener(listener) }
    }

    func authenticate(email: String, password: String, registering: Bool) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if registering {
            _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } else {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }

    func resetPassword(email: String) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        try await Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
    }
}
