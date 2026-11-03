import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var items: [TaskItem] = []
    @Published private(set) var isLoading = true
    @Published private(set) var isWriting = false
    @Published private(set) var isFromCache = false
    @Published var errorMessage: String?
    private var listener: ListenerRegistration?
    private var generation = UUID()
    private let userID: String
    private let database: Firestore

    init(userID: String) {
        self.userID = userID
        database = Firestore.firestore()
    }

    private var collection: CollectionReference {
        database.collection("users").document(userID).collection("tasks")
    }

    func startListening() {
        stopListening()
        isLoading = true
        errorMessage = nil
        let currentGeneration = generation
        listener = collection.order(by: "createdAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self, self.generation == currentGeneration else { return }
                    self.isLoading = false
                    if let error {
                        self.items = []
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        self.items = try snapshot.documents.map { try TaskItem(document: $0) }
                        self.isFromCache = snapshot.metadata.isFromCache
                        self.errorMessage = nil
                    } catch {
                        self.items = []
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }

    func stopListening() {
        generation = UUID()
        listener?.remove()
        listener = nil
        items = []
    }

    deinit { listener?.remove() }

    func save(draft: TaskDraft, existing: TaskItem?) async throws {
        try draft.validate()
        try checkSession()
        isWriting = true
        defer { isWriting = false }
        var data: [String: Any] = [
            "title": draft.trimmedTitle,
            "notes": draft.notes,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let existing {
            try await collection.document(existing.id).updateData(data)
        } else {
            data["isDone"] = false
            data["createdAt"] = FieldValue.serverTimestamp()
            try await collection.document().setData(data)
        }
    }

    func toggle(_ item: TaskItem) async throws {
        try checkSession()
        isWriting = true
        defer { isWriting = false }
        try await collection.document(item.id).updateData([
            "isDone": !item.isDone, "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func delete(_ item: TaskItem) async throws {
        try checkSession()
        isWriting = true
        defer { isWriting = false }
        try await collection.document(item.id).delete()
    }

    private func checkSession() throws {
        guard Auth.auth().currentUser?.uid == userID else {
            throw NSError(domain: "TaskManager", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Your session has changed. Sign in again."])
        }
        guard !isWriting else {
            throw NSError(domain: "TaskManager", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "Wait for the current change to finish."])
        }
    }
}
