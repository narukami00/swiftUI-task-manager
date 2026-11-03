import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var session: AuthStore
    @State private var registering = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var message: String?

    private var validEmail: Bool {
        let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.contains("@") && !value.contains(" ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48)).foregroundStyle(.indigo)
                        Text(registering ? "Make room for what matters." : "A little focus. A clearer day.")
                            .font(.title2.bold())
                        Text("Keep your tasks together, wherever you sign in.").foregroundStyle(.secondary)
                    }.padding(.vertical)
                }
                Section(registering ? "Create your account" : "Welcome back") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(registering ? .newPassword : .password)
                    if registering {
                        SecureField("Confirm password", text: $confirmation).textContentType(.newPassword)
                        Text("Use at least 6 characters, or the stronger policy set in Firebase.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack {
                            Spacer()
                            if session.isBusy { ProgressView() }
                            Text(registering ? "Create account" : "Sign in").bold()
                            Spacer()
                        }
                    }
                    .disabled(!validEmail || password.isEmpty || (registering && (password.count < 6 || password != confirmation)))
                }
                Section {
                    Button(registering ? "Already have an account? Sign in" : "New here? Create an account") {
                        registering.toggle()
                        password = ""
                        confirmation = ""
                    }
                    if !registering {
                        Button("Send password reset email") {
                            Task {
                                do {
                                    try await session.resetPassword(email: email)
                                    message = "If an account exists for this email, you'll receive password reset instructions. Check your spam folder too."
                                } catch { message = error.localizedDescription }
                            }
                        }.disabled(!validEmail)
                    }
                }
            }
            .disabled(session.isBusy)
            .navigationTitle("TaskManager")
            .alert("Account", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func authenticate() async {
        do { try await session.authenticate(email: email, password: password, registering: registering) }
        catch { message = error.localizedDescription }
    }
}
