import Foundation
import FirebaseFirestore

struct TaskItem: Identifiable {
    let id: String
    let title: String
    let notes: String
    let isDone: Bool
    let createdAt: Date?

    init(document: QueryDocumentSnapshot) throws {
        let data = document.data()
        guard let title = data["title"] as? String,
              let notes = data["notes"] as? String,
              let isDone = data["isDone"] as? Bool else {
            throw TaskInputError.invalidDocument
        }
        id = document.documentID
        self.title = title
        self.notes = notes
        self.isDone = isDone
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
}

enum TaskInputError: LocalizedError {
    case invalidTitle, invalidNotes, invalidDocument
    var errorDescription: String? {
        switch self {
        case .invalidTitle: return "Use a title between 1 and 120 characters."
        case .invalidNotes: return "Keep the description to 500 characters or fewer."
        case .invalidDocument: return "A task has an unsupported format. Check its fields in Firestore."
        }
    }
}

struct TaskDraft {
    var title: String
    var notes: String

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    // Count Unicode scalars to match Firestore rule string sizes, including emoji.
    var isValid: Bool {
        (1...120).contains(trimmedTitle.unicodeScalars.count) && notes.unicodeScalars.count <= 500
    }

    func validate() throws {
        guard (1...120).contains(trimmedTitle.unicodeScalars.count) else { throw TaskInputError.invalidTitle }
        guard notes.unicodeScalars.count <= 500 else { throw TaskInputError.invalidNotes }
    }
}
