import SwiftUI

private enum TaskFilter: String, CaseIterable {
    case all = "All", active = "Active", done = "Done"
}

private struct TaskEditorRoute: Identifiable {
    let id = UUID()
    let item: TaskItem?
}

struct TaskListView: View {
    let email: String
    @EnvironmentObject private var session: AuthStore
    @StateObject private var store: TaskStore
    @State private var filter: TaskFilter = .all
    @State private var search = ""
    @State private var editor: TaskEditorRoute?
    @State private var deletion: TaskItem?
    @State private var confirmingSignOut = false
    @State private var actionError: String?

    init(userID: String, email: String) {
        self.email = email
        _store = StateObject(wrappedValue: TaskStore(userID: userID))
    }

    private var visibleItems: [TaskItem] {
        store.items.filter { item in
            let matchesFilter = filter == .all || (filter == .done ? item.isDone : !item.isDone)
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
            return matchesFilter && (query.isEmpty || item.title.localizedCaseInsensitiveContains(query)
                || item.notes.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(store.items.filter { !$0.isDone }.count) active · \(store.items.filter(\.isDone).count) completed")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Picker("Show tasks", selection: $filter) {
                        ForEach(TaskFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                }.padding()
                if store.isWriting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Saving to Firebase… Internet is needed to finish.")
                            .font(.caption)
                    }.padding(.horizontal).padding(.bottom, 8)
                } else if store.isFromCache && !store.isLoading {
                    Label("Showing cached tasks. Reconnecting…", systemImage: "wifi.slash")
                        .font(.caption).foregroundStyle(.secondary).padding(.bottom, 8)
                }
                workspace
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My tasks")
            .searchable(text: $search, prompt: "Search your tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Text(email)
                        Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right") {
                            confirmingSignOut = true
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }.accessibilityLabel("Account").disabled(store.isWriting)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add task", systemImage: "plus") { editor = TaskEditorRoute(item: nil) }
                        .disabled(store.isWriting)
                }
            }
            .sheet(item: $editor) { route in
                TaskEditorView(store: store, existing: route.item)
            }
            .confirmationDialog("Delete this task?", isPresented: Binding(
                get: { deletion != nil }, set: { if !$0 { deletion = nil } }
            ), titleVisibility: .visible) {
                Button("Delete task", role: .destructive) {
                    guard let item = deletion else { return }
                    deletion = nil
                    Task { await delete(item) }
                }
                Button("Cancel", role: .cancel) { deletion = nil }
            } message: { Text(deletion?.title ?? "") }
            .confirmationDialog("Sign out?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    do {
                        try session.signOut()
                        store.stopListening()
                    } catch { actionError = error.localizedDescription }
                }
            } message: { Text("Your tasks stay in your Firebase account.") }
            .alert("Couldn't save your change", isPresented: Binding(
                get: { actionError != nil }, set: { if !$0 { actionError = nil } }
            )) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: { Text(actionError ?? "") }
            .onAppear { store.startListening() }
            .onDisappear { store.stopListening() }
        }
    }

    @ViewBuilder
    private var workspace: some View {
        if store.isLoading {
            Spacer()
            ProgressView("Loading tasks…")
            Spacer()
        } else if let error = store.errorMessage {
            ContentUnavailableView {
                Label("Couldn't load tasks", systemImage: "exclamationmark.icloud")
            } description: { Text(error) } actions: {
                Button("Try again") { store.startListening() }.buttonStyle(.bordered)
            }
        } else if visibleItems.isEmpty {
            ContentUnavailableView {
                Label(search.isEmpty ? "A little breathing room" : "No matching tasks",
                      systemImage: search.isEmpty ? "checkmark.circle" : "magnifyingglass")
            } description: {
                Text(search.isEmpty ? "Add a task, or switch filters to see more." : "Try a different title or description.")
            } actions: {
                if search.isEmpty {
                    Button("Add your next task") { editor = TaskEditorRoute(item: nil) }
                        .buttonStyle(.borderedProminent).disabled(store.isWriting)
                }
            }
        } else {
            List(visibleItems) { item in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        Task {
                            do { try await store.toggle(item) }
                            catch { actionError = error.localizedDescription }
                        }
                    } label: {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.title2).foregroundStyle(item.isDone ? Color.indigo : Color.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(item.isDone ? "Mark \(item.title) active" : "Complete \(item.title)")
                    Button { editor = TaskEditorRoute(item: item) } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.headline)
                                .strikethrough(item.isDone)
                                .foregroundStyle(item.isDone ? .secondary : .primary)
                            if !item.notes.isEmpty {
                                Text(item.notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                            }
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Edit task")
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) { deletion = item }
                    Button("Edit") { editor = TaskEditorRoute(item: item) }.tint(.indigo)
                }
                .contextMenu {
                    Button("Edit", systemImage: "pencil") { editor = TaskEditorRoute(item: item) }
                    Button("Delete", systemImage: "trash", role: .destructive) { deletion = item }
                }
                .disabled(store.isWriting)
            }.listStyle(.insetGrouped)
        }
    }

    private func delete(_ item: TaskItem) async {
        do { try await store.delete(item) }
        catch { actionError = error.localizedDescription }
    }
}
