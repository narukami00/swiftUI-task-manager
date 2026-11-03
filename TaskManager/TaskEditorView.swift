import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TaskStore
    let existing: TaskItem?
    @State private var draft: TaskDraft
    @State private var errorMessage: String?
    @State private var confirmingDiscard = false

    init(store: TaskStore, existing: TaskItem?) {
        self.store = store
        self.existing = existing
        _draft = State(initialValue: TaskDraft(title: existing?.title ?? "", notes: existing?.notes ?? ""))
    }

    private var hasChanges: Bool {
        draft.title != (existing?.title ?? "") || draft.notes != (existing?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What needs doing?") {
                    TextField("Task title", text: $draft.title, axis: .vertical).lineLimit(1...4)
                    Text("\(draft.trimmedTitle.unicodeScalars.count)/120")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Short description") {
                    TextField("Add a few details (optional)", text: $draft.notes, axis: .vertical)
                        .lineLimit(4...10)
                    Text("\(draft.notes.unicodeScalars.count)/500")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if store.isWriting {
                    Section {
                        HStack { ProgressView(); Text("Waiting for Firebase to save…") }
                        Text("Keep the app open and connect to the internet. Your edit closes after the server confirms it.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(store.isWriting)
            .navigationTitle(existing == nil ? "New task" : "Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { confirmingDiscard = true } else { dismiss() }
                    }.disabled(store.isWriting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await store.save(draft: draft, existing: existing)
                                dismiss()
                            } catch { errorMessage = error.localizedDescription }
                        }
                    }.disabled(!draft.isValid || !hasChanges || store.isWriting)
                }
            }
            .interactiveDismissDisabled(hasChanges || store.isWriting)
            .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) { }
            }
            .alert("Couldn't save task", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }
}
