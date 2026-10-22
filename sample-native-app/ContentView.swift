import SwiftUI

private enum Palette {
    static let background = Color(hex: 0xF8F7F3)
    static let ink = Color(hex: 0x252824)
    static let muted = Color(hex: 0x85877F)
    static let line = Color(hex: 0xE6E6DF)
    static let orange = Color(hex: 0xD85C35)
    static let green = Color(hex: 0x548364)
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255, opacity: 1) }
}

struct PullRequest: Identifiable, Codable {
    let id: Int
    let number: Int
    let title: String
    let user: Author
    let state: String
    let draft: Bool?
    let body: String?
    let html_url: String
    let created_at: String
    var repository: String = ""
    var review: String = "Review requested"
    var tag: String = "enhancement"
    var additions: Int = 128
    var deletions: Int = 34
    var comments: Int = 3
    struct Author: Codable { let login: String }
    enum CodingKeys: String, CodingKey { case id, number, title, user, state, draft, body, html_url, created_at, repository, review, tag, additions, deletions, comments }
    var isDraft: Bool { draft == true }
    var status: String { state == "closed" ? "Closed" : isDraft ? "Draft" : "Open" }
    var color: Color { state == "closed" ? .purple : isDraft ? Palette.muted : Palette.green }
    var initials: String { String(user.login.prefix(2)).uppercased() }
    var age: String {
        guard let date = ISO8601DateFormatter().date(from: created_at) else { return "2h" }
        let hours = max(1, Int(Date().timeIntervalSince(date) / 3600))
        return hours < 24 ? "\(hours)h" : "\(hours / 24)d"
    }
    static let samples: [PullRequest] = [
        .init(id: 1, number: 7214, title: "Add support for Server Actions in the app router", user: .init(login: "shuding"), state: "open", draft: false, body: "This update adds first-class support for Server Actions in the app router.\n\nServer-side mutations can now be called directly from your components, with progressive enhancement and built-in cache revalidation.\n\nWhat changed\n• Add action handling to the app router\n• Improve error boundaries and loading states\n• Include coverage for progressive enhancement", html_url: "https://github.com/vercel/next.js/pulls", created_at: "", repository: "vercel / next.js", review: "Review requested", tag: "feature", additions: 248, deletions: 42, comments: 8),
        .init(id: 2, number: 1842, title: "Fix hydration mismatch in navigation menu", user: .init(login: "pacocoursey"), state: "open", draft: false, body: "Ensures the navigation menu produces consistent markup during server rendering and hydration. Adds a regression case for nested menus.", html_url: "https://github.com/radix-ui/primitives/pulls", created_at: "", repository: "radix-ui / primitives", review: "Changes requested", tag: "bug", additions: 36, deletions: 12, comments: 4),
        .init(id: 3, number: 589, title: "Introduce a new color system for themes", user: .init(login: "joshwcomeau"), state: "open", draft: false, body: "A new semantic color system with accessible contrast, dark mode support, and a simpler theme API.", html_url: "https://github.com/tailwindlabs/tailwindcss/pulls", created_at: "", repository: "tailwindlabs / tailwindcss", review: "Approved", tag: "design", additions: 182, deletions: 64, comments: 12),
        .init(id: 4, number: 3106, title: "Refactor the query cache internals", user: .init(login: "TkDodo"), state: "open", draft: true, body: "Work in progress: simplify cache subscriptions and reduce unnecessary notifications.", html_url: "https://github.com/TanStack/query/pulls", created_at: "", repository: "TanStack / query", review: "Draft", tag: "refactor", additions: 420, deletions: 208, comments: 2),
        .init(id: 5, number: 7201, title: "Improve image loading performance", user: .init(login: "timneutkens"), state: "closed", draft: false, body: "Reduces layout shifts and improves image loading priorities.", html_url: "https://github.com/vercel/next.js/pulls", created_at: "", repository: "vercel / next.js", review: "Approved", tag: "performance", additions: 96, deletions: 28, comments: 5),
        .init(id: 6, number: 1839, title: "Improve keyboard focus management", user: .init(login: "jjenzz"), state: "open", draft: false, body: "Makes keyboard navigation more predictable across nested components.", html_url: "https://github.com/radix-ui/primitives/pulls", created_at: "", repository: "radix-ui / primitives", review: "Review requested", tag: "accessibility", additions: 72, deletions: 18, comments: 6)
    ]
}

extension PullRequest {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        number = try values.decode(Int.self, forKey: .number)
        title = try values.decode(String.self, forKey: .title)
        user = try values.decode(Author.self, forKey: .user)
        state = try values.decode(String.self, forKey: .state)
        draft = try values.decodeIfPresent(Bool.self, forKey: .draft)
        body = try values.decodeIfPresent(String.self, forKey: .body)
        html_url = try values.decode(String.self, forKey: .html_url)
        created_at = try values.decode(String.self, forKey: .created_at)
        repository = try values.decodeIfPresent(String.self, forKey: .repository) ?? ""
        review = try values.decodeIfPresent(String.self, forKey: .review) ?? "View on GitHub"
        tag = try values.decodeIfPresent(String.self, forKey: .tag) ?? "pull request"
        additions = try values.decodeIfPresent(Int.self, forKey: .additions) ?? 0
        deletions = try values.decodeIfPresent(Int.self, forKey: .deletions) ?? 0
        comments = try values.decodeIfPresent(Int.self, forKey: .comments) ?? 0
    }
}

struct ContentView: View {
    @State private var requests = PullRequest.samples
    @State private var tab = "Inbox"
    @State private var filter = "Open"
    @State private var search = ""
    @State private var repository = "All repositories"
    @State private var showRepositories = false
    @State private var selected: PullRequest?
    @AppStorage("savedPullRequests") private var savedIDs = ""
    @AppStorage("savedPullRequestData") private var savedData = ""
    private var savedRequests: [PullRequest] {
        (try? JSONDecoder().decode([PullRequest].self, from: Data(savedData.utf8))) ?? []
    }
    @State private var live = false
    @State private var loading = false
    @State private var error: String?
    @State private var sortNewest = true
    private var saved: Set<String> { Set(savedIDs.split(separator: ",").map(String.init)) }
    private var visible: [PullRequest] {
        let items = (tab == "Saved" ? savedRequests : requests).filter { pr in
            (tab != "Saved" || saved.contains(String(pr.id))) &&
            (repository == "All repositories" || pr.repository == repository) &&
            (filter == "All" || pr.status == filter) &&
            (search.isEmpty || "\(pr.title) \(pr.repository) \(pr.number) \(pr.user.login)".localizedCaseInsensitiveContains(search))
        }
        return sortNewest ? items : items.reversed()
    }
    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    if tab == "Repositories" { repositoryContent } else { inboxContent }
                }.padding(.horizontal, 24).padding(.top, 27).padding(.bottom, 24)
            }
            bottomBar
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showRepositories) { RepositoryPicker(repository: $repository, live: live, onLoad: loadRepository) }
        .sheet(item: $selected) { pr in DetailView(pr: pr, saved: saved.contains(String(pr.id))) { toggleSaved(pr) } }
        .alert("Couldn’t load pull requests", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.pull").font(.system(size: 22, weight: .semibold)).foregroundStyle(Palette.orange)
            Text("branch").font(.system(size: 27, weight: .bold, design: .rounded)).tracking(-1.3)
            Text("/ your code, in motion").font(.system(size: 11)).foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
            Text("JD").font(.system(size: 12, weight: .semibold)).frame(width: 35, height: 35).background(Color(hex: 0xE8EBDD), in: Circle()).overlay(Circle().stroke(.white, lineWidth: 3)).accessibilityLabel("Local workspace")
        }.padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 18).overlay(alignment: .bottom) { Rectangle().fill(Palette.line).frame(height: 1) }
    }
    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) { Circle().fill(Palette.green).frame(width: 5, height: 5); Text(live ? "GITHUB PUBLIC REPOSITORY" : "YOUR WORKSPACE · DEMO").tracking(1.7).font(.system(size: 9, weight: .semibold)).foregroundStyle(Palette.muted) }
            HStack(alignment: .firstTextBaseline) {
                Text(tab == "Saved" ? "Saved for later." : tab == "Repositories" ? "Your repositories." : "Good code starts\nwith a conversation.")
                    .font(.system(size: 34, weight: .regular, design: .serif)).tracking(-1.3).lineSpacing(0)
                Spacer(minLength: 0)
            }
            Text(tab == "Saved" ? "A little space for the changes worth coming back to." : tab == "Repositories" ? "Keep the projects you care about close." : "A little focus. A better review. Keep things moving.")
                .font(.system(size: 12)).foregroundStyle(Palette.muted).padding(.top, 2)
        }
    }
    private var inboxContent: some View {
        VStack(spacing: 20) {
            if tab == "Inbox" {
                HStack(spacing: 0) {
                    stat("\(requests.filter { $0.status == "Open" }.count)", "Open", "arrow.triangle.pull", Palette.green)
                    Rectangle().fill(Palette.line).frame(width: 1, height: 35)
                    stat("\(requests.filter { $0.review == "Review requested" && $0.status == "Open" }.count)", "To review", "bubble.left", Palette.orange)
                    Rectangle().fill(Palette.line).frame(width: 1, height: 35)
                    stat("\(requests.filter { $0.isDraft }.count)", "Draft", "circle.dashed", Palette.muted)
                }.padding(.vertical, 18).background(Color(hex: 0xF0F0E9), in: RoundedRectangle(cornerRadius: 14))
            }
            VStack(spacing: 14) {
                HStack {
                    Button { showRepositories = true } label: {
                        HStack(spacing: 7) { Image(systemName: "tray.2"); Text(repository); Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold)) }.font(.system(size: 12, weight: .medium))
                    }.accessibilityIdentifier("repositoryPicker")
                    Spacer()
                    Button { sortNewest.toggle() } label: { Image(systemName: "arrow.up.arrow.down").font(.system(size: 14)) }.accessibilityLabel(sortNewest ? "Sort oldest first" : "Sort newest first")
                }
                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                    TextField("Search pull requests…", text: $search).font(.system(size: 13)).autocorrectionDisabled().accessibilityIdentifier("searchPRs")
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.muted) }.accessibilityLabel("Clear search") }
                }.padding(13).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.line))
                HStack(spacing: 6) {
                    ForEach(["Open", "Closed", "Draft", "All"], id: \.self) { item in
                        Button { filter = item } label: {
                            HStack(spacing: 5) { Text(item); if item == "Open" { Text("\(requests.filter { $0.status == "Open" }.count)").font(.system(size: 10)).padding(.horizontal, 5).padding(.vertical, 2).background(filter == item ? .white.opacity(0.2) : Palette.line, in: Capsule()) } }
                                .font(.system(size: 12, weight: .medium)).padding(.horizontal, 13).frame(height: 32).background(filter == item ? Palette.ink : .clear, in: Capsule()).foregroundStyle(filter == item ? .white : Palette.muted)
                        }.accessibilityIdentifier("filter\(item)")
                    }
                    Spacer(minLength: 0)
                }
            }
            HStack {
                Text(tab == "Saved" ? "SAVED PULL REQUESTS" : "PULL REQUESTS").font(.system(size: 9, weight: .semibold)).tracking(1.8)
                Text("\(visible.count)").font(.system(size: 10)).foregroundStyle(Palette.muted)
                Spacer()
                Text(sortNewest ? "Newest first" : "Oldest first").font(.system(size: 10)).foregroundStyle(Palette.muted)
            }.padding(.top, 3)
            if loading { ProgressView("Loading from GitHub…").padding(25) }
            else if visible.isEmpty { VStack(spacing: 10) { Image(systemName: "tray").font(.system(size: 28)); Text("All clear here.").font(.system(size: 21, design: .serif)); Text("Try another filter or save a pull request.").font(.system(size: 12)).foregroundStyle(Palette.muted) }.frame(maxWidth: .infinity).padding(.vertical, 35) }
            else {
                VStack(spacing: 12) { ForEach(visible) { pr in
                    Button { selected = pr } label: { PullRequestCard(pr: pr, isSaved: saved.contains(String(pr.id))) }.buttonStyle(.plain).accessibilityIdentifier("pr\(pr.id)")
                } }
            }
            HStack(spacing: 5) { Image(systemName: "leaf"); Text("A calmer place to keep up with code.") }.font(.system(size: 10)).foregroundStyle(Palette.muted).padding(.vertical, 8)
        }
    }
    private func stat(_ number: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) { HStack(spacing: 6) { Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color); Text(number).font(.system(size: 23, weight: .medium, design: .rounded)) }; Text(label).font(.system(size: 11)).foregroundStyle(Palette.muted) }.frame(maxWidth: .infinity)
    }
    private var bottomBar: some View {
        HStack {
            ForEach([( "Inbox", "tray"), ("Repositories", "square.stack.3d.up"), ("Saved", "bookmark")], id: \.0) { name, icon in
                Button { tab = name; search = ""; filter = name == "Saved" ? "All" : "Open" } label: {
                    VStack(spacing: 5) { Image(systemName: icon + (tab == name ? ".fill" : "")).font(.system(size: 19)); Text(name).font(.system(size: 10, weight: tab == name ? .semibold : .regular)) }.foregroundStyle(tab == name ? Palette.orange : Palette.muted).frame(maxWidth: .infinity).frame(height: 53)
                }.accessibilityIdentifier("tab\(name)")
            }
        }.padding(.top, 8).padding(.horizontal, 25).background(Palette.background).overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
    }
    private var repositoryContent: some View {
        VStack(spacing: 12) {
            Button { showRepositories = true } label: { Label("Browse a public GitHub repository", systemImage: "plus").font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity).padding(18).foregroundStyle(.white).background(Palette.ink, in: RoundedRectangle(cornerRadius: 12)) }
            ForEach(Array(Set(requests.map(\.repository))).sorted(), id: \.self) { repo in
                Button { repository = repo; tab = "Inbox"; filter = "All" } label: {
                    HStack { Image(systemName: "book.closed").foregroundStyle(Palette.orange); VStack(alignment: .leading, spacing: 5) { Text(repo).font(.system(size: 14, weight: .medium)); Text("\(requests.filter { $0.repository == repo }.count) pull requests").font(.system(size: 11)).foregroundStyle(Palette.muted) }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(Palette.muted) }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain)
            }
            if live { Button("Return to demo workspace") { requests = PullRequest.samples; live = false; repository = "All repositories" }.font(.system(size: 13)).padding() }
        }
    }
    private func toggleSaved(_ pr: PullRequest) {
        var ids = saved
        if !ids.insert(String(pr.id)).inserted { ids.remove(String(pr.id)) }
        savedIDs = ids.sorted().joined(separator: ",")
        var items = savedRequests.filter { $0.id != pr.id }
        if ids.contains(String(pr.id)) { items.append(pr) }
        if let data = try? JSONEncoder().encode(items) {
            savedData = String(decoding: data, as: UTF8.self)
        }
    }
    private func loadRepository(_ name: String) {
        showRepositories = false; loading = true; tab = "Inbox"; filter = "All"; search = ""
        Task {
            do {
                let parts = name.split(separator: "/")
                guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isLetter || $0.isNumber || "-_.".contains($0) } }), let url = URL(string: "https://api.github.com/repos/\(name)/pulls?state=all&per_page=50") else { throw BrowserError.message("Enter a repository as owner/name, for example vercel/next.js.") }
                var request = URLRequest(url: url); request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept"); request.setValue("Branch-iOS", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let response = response as? HTTPURLResponse else { throw BrowserError.message("GitHub did not respond. Please try again.") }
                guard response.statusCode == 200 else { throw BrowserError.message(response.statusCode == 404 ? "Repository not found. Choose a public repository and check its name." : "GitHub returned \(response.statusCode). Please try again later.") }
                var items = try JSONDecoder().decode([PullRequest].self, from: data)
                for i in items.indices { items[i].repository = name.replacingOccurrences(of: "/", with: " / "); items[i].review = "View on GitHub"; items[i].tag = "pull request" }
                requests = items; repository = "All repositories"; live = true
            } catch { self.error = error.localizedDescription }
            loading = false
        }
    }
}
private enum BrowserError: LocalizedError { case message(String); var errorDescription: String? { if case .message(let value) = self { return value }; return nil } }

private struct PullRequestCard: View {
    let pr: PullRequest
    let isSaved: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "book.closed").font(.system(size: 10))
                Text(pr.repository).font(.system(size: 10, weight: .medium))
                Spacer(minLength: 2)
                Text("#" + String(pr.number)).font(.system(size: 10, design: .monospaced))
                if isSaved { Image(systemName: "bookmark.fill").foregroundStyle(Palette.orange).font(.system(size: 10)) }
            }.foregroundStyle(Palette.muted)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: pr.isDraft ? "circle.dashed" : "arrow.triangle.pull").font(.system(size: 16, weight: .medium)).foregroundStyle(pr.color).padding(.top, 2)
                Text(pr.title).font(.system(size: 16, weight: .semibold)).tracking(-0.3).lineSpacing(3).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 6) {
                Text(pr.tag).font(.system(size: 9, weight: .medium)).padding(.horizontal, 8).padding(.vertical, 4).foregroundStyle(tagColor).background(tagColor.opacity(0.08), in: Capsule())
                Spacer()
                if pr.id < 10 { Text("+\(pr.additions)").foregroundStyle(Palette.green); Text("−\(pr.deletions)").foregroundStyle(Palette.orange) }
            }.font(.system(size: 10, design: .monospaced)).padding(.leading, 26)
            Rectangle().fill(Palette.line.opacity(0.65)).frame(height: 1)
            HStack(spacing: 6) {
                Text(pr.initials).font(.system(size: 8, weight: .bold)).frame(width: 22, height: 22).background(avatarColor, in: Circle()).foregroundStyle(Palette.ink)
                Text(pr.user.login).font(.system(size: 10, weight: .medium)).lineLimit(1)
                Text("· \(pr.age) ago").font(.system(size: 10)).foregroundStyle(Palette.muted)
                Spacer(minLength: 3)
                Image(systemName: pr.review == "Approved" ? "checkmark.circle" : pr.review == "Changes requested" ? "arrow.uturn.backward" : "circle.dotted").font(.system(size: 10))
                Text(pr.review).font(.system(size: 9)).lineLimit(1)
            }.foregroundStyle(pr.review == "Approved" ? Palette.green : Palette.muted)
        }.padding(16).background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(Palette.line.opacity(0.8), lineWidth: 0.7))
    }
    private var tagColor: Color { pr.tag == "bug" ? Palette.orange : pr.tag == "design" ? Color(hex: 0x8B70A6) : Palette.green }
    private var avatarColor: Color { pr.id % 2 == 0 ? Color(hex: 0xE5D6C7) : Color(hex: 0xDDE5D5) }
}

private struct RepositoryPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var repository: String
    let live: Bool
    let onLoad: (String) -> Void
    @State private var name = ""
    var body: some View {
        NavigationStack {
            Form {
                if !live { Section("Demo workspace") {
                    ForEach(["All repositories", "vercel / next.js", "radix-ui / primitives", "tailwindlabs / tailwindcss", "TanStack / query"], id: \.self) { repo in
                        Button { repository = repo; dismiss() } label: { HStack { Text(repo).foregroundStyle(Palette.ink); Spacer(); if repository == repo { Image(systemName: "checkmark").foregroundStyle(Palette.orange) } } }
                    }
                } }
                Section { TextField("owner/repository", text: $name).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("repositoryName"); Button("Load pull requests from GitHub") { onLoad(name.trimmingCharacters(in: .whitespacesAndNewlines)) }.disabled(name.isEmpty) } header: { Text("Browse a public repository") } footer: { Text("Loads the latest 50 public pull requests. No account required. Private repositories are not supported.") }
            }.navigationTitle("Repositories").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }.tint(Palette.orange)
        }.presentationDetents([.medium, .large])
    }
}

private struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    let pr: PullRequest
    @State var saved: Bool
    let toggleSaved: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(pr.repository.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.5).foregroundStyle(Palette.muted)
                    Text(pr.title).font(.system(size: 30, design: .serif)).tracking(-0.7)
                    HStack(spacing: 8) { Label(pr.status, systemImage: pr.isDraft ? "circle.dashed" : "arrow.triangle.pull").font(.system(size: 12, weight: .medium)).padding(.horizontal, 11).padding(.vertical, 7).background(pr.color.opacity(0.12), in: Capsule()).foregroundStyle(pr.color); Text("#" + String(pr.number) + " · " + pr.user.login).font(.system(size: 12)).foregroundStyle(Palette.muted) }
                    Divider()
                    HStack { Text("Conversation").font(.system(size: 15, weight: .semibold)); Spacer(); Image(systemName: "text.bubble").foregroundStyle(Palette.orange) }
                    Text(pr.body?.isEmpty == false ? pr.body! : "No description provided.").font(.system(size: 14)).lineSpacing(7).textSelection(.enabled)
                    if pr.id < 10 { HStack { Label("+\(pr.additions) additions", systemImage: "plus").foregroundStyle(Palette.green); Spacer(); Text("−\(pr.deletions) deletions").foregroundStyle(Palette.orange) }.font(.system(size: 11, design: .monospaced)).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 10)) }
                    Button { saved.toggle(); toggleSaved() } label: { Label(saved ? "Saved for later" : "Save for later", systemImage: saved ? "bookmark.fill" : "bookmark").font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity).padding(17).background(Palette.ink, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white) }.accessibilityIdentifier("savePR")
                    if let url = URL(string: pr.html_url) { Link(destination: url) { HStack { Text(pr.id < 10 ? "Browse repository on GitHub" : "Open pull request on GitHub"); Image(systemName: "arrow.up.right") }.font(.system(size: 13)).frame(maxWidth: .infinity).foregroundStyle(Palette.orange) } }
                    if pr.id < 10 { Text("This is a sample pull request. Load a public repository to browse live GitHub data.").font(.system(size: 11)).foregroundStyle(Palette.muted) }
                }.padding(25)
            }.background(Palette.background).navigationTitle("Pull request").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }.tint(Palette.orange)
        }
    }
}
