import SwiftUI

private struct Todo: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: String
    var important = false
    var completed = false

    static let storageKey = "daylight.tasks.v1"
    static func load() -> [Todo] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Todo].self, from: data) { return saved }
        return [
            Todo(title: "Make room for a little focus", category: "Personal", important: true),
            Todo(title: "Plan the week ahead", category: "Work"),
            Todo(title: "Take a walk outside", category: "Health"),
            Todo(title: "Start something good", category: "Personal", completed: true)
        ]
    }
}

private enum TaskFilter: String, CaseIterable {
    case all = "All", active = "Active", done = "Done"
}

struct ContentView: View {
    @State private var tasks = Todo.load()
    @State private var filter = TaskFilter.all
    @State private var editingTask: Todo?
    private let ink = Color(red: 0.16, green: 0.23, blue: 0.22)
    private let coral = Color(red: 0.83, green: 0.36, blue: 0.25)
    private let paper = Color(red: 0.97, green: 0.96, blue: 0.93)

    private var completedCount: Int { tasks.filter(\.completed).count }
    private var visibleTasks: [Todo] {
        tasks.filter { filter == .all || (filter == .done ? $0.completed : !$0.completed) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                progressCard
                taskSection
                Text("A little progress, every day.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ink.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(paper.ignoresSafeArea())
        .foregroundStyle(ink)
        .tint(coral)
        .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
        .safeAreaInset(edge: .bottom) { addBar }
        .sheet(item: $editingTask) { selectedTask in
            TaskEditor(task: selectedTask, isEditing: tasks.contains { $0.id == selectedTask.id }) { task in
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index] = task
                } else {
                    tasks.append(task)
                    filter = .all
                }
            }
        }
        .onChange(of: tasks) { _, value in
            if let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: Todo.storageKey)
            }
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 18))
                .foregroundStyle(coral)
            Text("daylight")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Spacer()
            Text("YOUR DAILY SPACE")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(ink.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(ink.opacity(0.5))
            Text("Small steps.\nBrighter days.")
                .font(.system(size: 39, weight: .regular, design: .serif))
                .tracking(-1.5)
                .fixedSize(horizontal: false, vertical: true)
            Text("A clear mind starts with a simple list.")
                .font(.system(size: 14))
                .foregroundStyle(ink.opacity(0.6))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("A LITTLE MOMENTUM")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.7)
                        .foregroundStyle(ink.opacity(0.6))
                    Text(tasks.isEmpty ? "Your fresh start" : completedCount == tasks.count ? "Look at you go!" : "You're on your way")
                        .font(.system(size: 22, design: .serif))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 25, weight: .light))
                    .foregroundStyle(coral)
                    .padding(10)
                    .background(.white.opacity(0.4), in: Circle())
            }
            VStack(spacing: 9) {
                ProgressView(value: Double(completedCount), total: Double(max(tasks.count, 1)))
                    .tint(coral)
                    .accessibilityLabel("Task progress")
                HStack {
                    Text("\(completedCount) of \(tasks.count) tasks complete")
                    Spacer()
                    Text(tasks.isEmpty ? "Let's begin" : "\(Int(Double(completedCount) / Double(tasks.count) * 100))%")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ink.opacity(0.65))
            }
        }
        .padding(22)
        .background(Color(red: 0.95, green: 0.87, blue: 0.79), in: RoundedRectangle(cornerRadius: 24))
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your list")
                    .font(.system(size: 25, design: .serif))
                Text("\(tasks.filter { !$0.completed }.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(ink.opacity(0.07), in: Capsule())
                Spacer()
                Text("MAKE SPACE FOR WHAT MATTERS")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(ink.opacity(0.4))
            }
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.snappy) { filter = option }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .foregroundStyle(filter == option ? .white : ink.opacity(0.6))
                            .background(filter == option ? ink : ink.opacity(0.05), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
            if visibleTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: filter == .done ? "checkmark.seal" : "leaf")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(coral)
                    Text(filter == .done ? "Good things take small steps" : "A little breathing room")
                        .font(.system(size: 19, design: .serif))
                    Text(filter == .done ? "Completed tasks will appear here." : "Add a task whenever you're ready.")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(visibleTasks) { task in taskRow(task) }
                }
            }
        }
    }

    private func taskRow(_ task: Todo) -> some View {
        HStack(spacing: 14) {
            Button {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    withAnimation(.snappy) { tasks[index].completed.toggle() }
                }
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 25, weight: .light))
                    .foregroundStyle(task.completed ? Color(red: 0.4, green: 0.55, blue: 0.43) : ink.opacity(0.22))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(task.completed ? "Reopen" : "Complete") \(task.title)")
            VStack(alignment: .leading, spacing: 7) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(task.completed)
                    .foregroundStyle(ink.opacity(task.completed ? 0.4 : 1))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Circle()
                        .fill(categoryColor(task.category))
                        .frame(width: 5, height: 5)
                    Text(task.category)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ink.opacity(0.5))
                    if task.important {
                        Text("PRIORITY")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(0.7)
                            .foregroundStyle(coral)
                    }
                }
            }
            Spacer(minLength: 0)
            Menu {
                Button("Edit task", systemImage: "pencil") {
                    editingTask = task
                }
                Button("Delete task", systemImage: "trash", role: .destructive) {
                    withAnimation { tasks.removeAll { $0.id == task.id } }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(ink.opacity(0.35))
                    .frame(width: 36, height: 44)
            }
            .accessibilityLabel("Options for \(task.title)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(.white.opacity(task.completed ? 0.5 : 0.9), in: RoundedRectangle(cornerRadius: 18))
    }

    private func categoryColor(_ category: String) -> Color {
        category == "Work" ? .blue : category == "Health" ? .green : coral
    }

    private var addBar: some View {
        Button {
            editingTask = Todo(title: "", category: "Personal")
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .medium))
                Text("Add a task")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .opacity(0.6)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 19)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(ink)
        .glassEffect(.regular.tint(Color(red: 0.93, green: 0.82, blue: 0.7)).interactive(), in: Capsule())
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }
}

private struct TaskEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Todo
    let onSave: (Todo) -> Void
    private let isEditing: Bool

    init(task: Todo, isEditing: Bool, onSave: @escaping (Todo) -> Void) {
        _draft = State(initialValue: task)
        self.isEditing = isEditing
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What’s on your mind?") {
                    TextField("Give your task a name", text: $draft.title, axis: .vertical)
                        .lineLimit(1...3)
                        .accessibilityIdentifier("taskTitleField")
                }
                Section("Make it yours") {
                    Picker("Category", selection: $draft.category) {
                        ForEach(["Personal", "Work", "Health"], id: \.self) { Text($0) }
                    }
                    Toggle("Mark as priority", isOn: $draft.important)
                }
            }
            .navigationTitle(isEditing ? "Edit task" : "A new beginning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("saveTaskButton")
                }
            }
            .tint(Color(red: 0.83, green: 0.36, blue: 0.25))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview { ContentView() }
