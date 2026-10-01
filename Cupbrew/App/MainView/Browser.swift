import AppKit
import Observation

/// The state of the main window and everything its toolbar, menus and rows
/// can do.
@Observable @MainActor
final class Browser {

    /// What the toolbar's action button does for the current selection.
    enum ToolbarAction {
        case none
        case install
        case uninstall
        case tap
        case untap
        case upgradeOne
        case upgradeMany
    }

    /// A question asked before a command runs.
    struct Confirmation {
        let title: String
        let message: String
        var confirmTitle = String(localized: "Yes")
        let action: () -> Void
    }

    /// The one formula the options sheet is about.
    struct OptionsRequest: Identifiable {
        let name: String
        var id: String { name }
    }

    let homebrew: Homebrew

    private(set) var sidebar = SidebarItem.installed

    var searchText = "" {
        didSet {
            // Searching looks through every formula, which the sidebar shows
            // by moving to that list.
            if !searchText.isEmpty { sidebar = .all }
            selection = []
        }
    }

    var selection: Set<String> = [] {
        didSet {
            if selection != oldValue { loadInfo() }
        }
    }

    /// `brew info` for the one selected formula, once it has loaded.
    private(set) var info: FormulaInfo?

    var confirmation: Confirmation?
    var operation: Operation?
    var optionsRequest: OptionsRequest?
    var popover: FormulaPopover?
    var bundleJob: BundleJob?
    var isAskingForTap = false
    var tapName = ""
    var showsBusyAlert = false

    /// Return and Delete act on the rows only while the rows have focus;
    /// anywhere else they belong to the text being typed.
    var isTableFocused = false
    private(set) var searchFocusRequest = 0

    let doctor = BrewRun()
    let update = BrewRun()

    private var infoTask: Task<Void, Never>?

    init(homebrew: Homebrew) {
        self.homebrew = homebrew
    }

    // MARK: - Lists

    var isSearching: Bool {
        !searchText.isEmpty
    }

    var isReady: Bool {
        homebrew.state == .ready
    }

    var rows: [Formula] {
        if isSearching {
            return homebrew.all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sidebar {
        case .installed: return homebrew.installed
        case .outdated: return homebrew.outdated
        case .all: return homebrew.all
        case .leaves: return homebrew.leaves
        case .repositories: return homebrew.repositories
        case .doctor, .update: return []
        }
    }

    /// Why the rows are missing, when Homebrew failed to list them.
    var rowsFailure: String? {
        let list = isSearching ? .all : sidebar.list
        return list.flatMap { homebrew.failures[$0] }
    }

    var footer: String {
        isSearching ? String(localized: "These are the results of your search.") : String(localized: sidebar.footer)
    }

    func count(of item: SidebarItem) -> Int? {
        switch item {
        case .installed: homebrew.installed.count
        case .outdated: homebrew.outdated.count
        case .all: homebrew.all.count
        case .leaves: homebrew.leaves.count
        case .repositories: homebrew.repositories.count
        case .doctor, .update: nil
        }
    }

    func select(_ item: SidebarItem) {
        searchText = ""
        sidebar = item
        selection = []
    }

    func focusSearch() {
        searchFocusRequest += 1
    }

    /// The selected formula when exactly one is selected.
    var selectedName: String? {
        selection.count == 1 ? selection.first : nil
    }

    var showsFormulaPanel: Bool {
        isSearching || sidebar != .repositories
    }

    var isBusy: Bool {
        doctor.isRunning || update.isRunning || operation?.run.isRunning == true || bundleJob?.run.isRunning == true
    }

    // MARK: - Toolbar

    var toolbarAction: ToolbarAction {
        if sidebar == .repositories && !isSearching {
            return selection.isEmpty ? .tap : .untap
        }
        if selection.isEmpty || sidebar.isTool { return .none }
        guard let name = selectedName else { return .upgradeMany }
        switch homebrew.status(of: name) {
        case .notInstalled: return .install
        case .installed: return .uninstall
        case .outdated: return sidebar == .outdated && !isSearching ? .upgradeOne : .uninstall
        }
    }

    func performToolbarAction() {
        switch toolbarAction {
        case .none: break
        case .install: install(selection)
        case .uninstall: uninstall(selection)
        case .tap: askForTap()
        case .untap: untap(selection)
        case .upgradeOne, .upgradeMany: upgrade(selection)
        }
    }

    // MARK: - What a set of rows allows

    func canInstall(_ names: Set<String>) -> Bool {
        single(names).map { homebrew.status(of: $0) == .notInstalled && listsFormulae } ?? false
    }

    func canUninstall(_ names: Set<String>) -> Bool {
        single(names).map { homebrew.status(of: $0) != .notInstalled && listsFormulae } ?? false
    }

    func canUpgrade(_ names: Set<String>) -> Bool {
        !names.isEmpty && listsFormulae && names.allSatisfy { homebrew.status(of: $0) == .outdated }
    }

    func canShowInfo(_ names: Set<String>) -> Bool {
        single(names) != nil && listsFormulae
    }

    func website(for names: Set<String>) -> URL? {
        guard let name = single(names), let info, info.name == Formula(name: name).shortName,
              let homepage = info.homepage else { return nil }
        return URL(string: homepage)
    }

    var canUpgradeAll: Bool {
        isReady && !homebrew.outdated.isEmpty
    }

    private var listsFormulae: Bool {
        isReady && (isSearching || (sidebar != .repositories && !sidebar.isTool))
    }

    private func single(_ names: Set<String>) -> String? {
        names.count == 1 ? names.first : nil
    }
}

// MARK: - Actions

extension Browser {

    func install(_ names: Set<String>) {
        guard let name = single(names) else { return }
        confirmation = Confirmation(
            title: String(localized: "Attention!"),
            message: String(localized: "Are you sure you want to install the formula '\(name)'?")
        ) { [weak self] in
            self?.perform(Operation(kind: .install, names: [name]))
        }
    }

    func installWithOptions(_ names: Set<String>) {
        guard let name = single(names), ensureIdle() else { return }
        optionsRequest = OptionsRequest(name: name)
    }

    /// Called by the options sheet once options are picked.
    func install(_ name: String, options: [String]) {
        confirmation = Confirmation(
            title: String(localized: "Attention!"),
            message: String(localized: "Are you sure you want to install the formula \(name) with the selected options?")
        ) { [weak self] in
            self?.perform(Operation(kind: .install, names: [name], options: options))
        }
    }

    func uninstall(_ names: Set<String>) {
        guard let name = single(names) else { return }
        confirmation = Confirmation(
            title: String(localized: "Attention!"),
            message: String(localized: "Are you sure you want to uninstall the formula '\(name)'?")
        ) { [weak self] in
            self?.perform(Operation(kind: .uninstall, names: [name]))
        }
    }

    func upgrade(_ names: Set<String>) {
        let names = names.sorted()
        guard !names.isEmpty else { return }
        let list = names.joined(separator: ", ")
        confirmation = Confirmation(
            title: String(localized: "Updating Formulae"),
            message: String(localized: "Are you sure you want to update these formulae: '\(list)'?")
        ) { [weak self] in
            self?.perform(Operation(kind: .upgrade, names: names))
        }
    }

    func upgradeAll() {
        confirmation = Confirmation(
            title: String(localized: "Updating all Outdated"),
            message: String(localized: "Are you sure you want to update all outdated formulae?")
        ) { [weak self] in
            self?.perform(Operation(kind: .upgradeAll))
        }
    }

    func askForTap() {
        guard ensureIdle() else { return }
        tapName = ""
        isAskingForTap = true
    }

    func tap() {
        let name = tapName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        perform(Operation(kind: .tap, names: [name]))
    }

    func untap(_ names: Set<String>) {
        guard let name = single(names) else { return }
        confirmation = Confirmation(
            title: String(localized: "Untapping Repository"),
            message: String(localized: "Are you sure you want to untap the repository '\(name)'?"),
            confirmTitle: String(localized: "OK")
        ) { [weak self] in
            self?.perform(Operation(kind: .untap, names: [name]))
        }
    }

    func cleanup() {
        perform(Operation(kind: .cleanup))
    }

    func showPopover(_ kind: FormulaPopover.Kind, for names: Set<String>) {
        guard let name = single(names) else { return }
        popover = FormulaPopover(kind: kind, name: name)
    }

    func openWebsite(for names: Set<String>) {
        if let url = website(for: names) { NSWorkspace.shared.open(url) }
    }

    func updateHomebrew() {
        select(.update)
        runTool(update, ["update"], finished: String(localized: "Update Homebrew"))
    }

    func runDoctor() {
        runTool(doctor, ["doctor"], finished: String(localized: "Homebrew Doctor"))
    }

    func exportBundle() {
        guard ensureIdle() else { return }
        let panel = NSSavePanel()
        panel.nameFieldLabel = String(localized: "Export To:")
        panel.prompt = String(localized: "Export")
        panel.nameFieldStringValue = BundleJob.fileName
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startBundle(BundleJob(kind: .export, file: url))
    }

    func importBundle() {
        guard ensureIdle() else { return }
        let panel = NSOpenPanel()
        let filter = BrewfileFilter()
        panel.delegate = filter
        panel.nameFieldLabel = String(localized: "Import From:")
        panel.prompt = String(localized: "Import")
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startBundle(BundleJob(kind: .import, file: url))
    }

    // MARK: - Running

    private func perform(_ operation: Operation) {
        guard ensureIdle(), let brew = homebrew.brew else { return }
        self.operation = operation
        Task {
            await operation.run.start(operation.arguments, with: brew)
            Attention.taskFinished([operation.title, operation.subject].joined(separator: " "))
            if operation.changesFormulae {
                await homebrew.reload()
                loadInfo()
            }
        }
    }

    private func runTool(_ run: BrewRun, _ arguments: [String], finished: String) {
        guard ensureIdle(), let brew = homebrew.brew else { return }
        Task {
            await run.start(arguments, with: brew)
            Attention.taskFinished(finished)
            if arguments == ["update"] { await homebrew.reload() }
        }
    }

    private func startBundle(_ job: BundleJob) {
        guard let brew = homebrew.brew else { return }
        bundleJob = job
        Task {
            await job.start(with: brew)
            if job.kind == .import { await homebrew.reload() }
        }
    }

    /// Homebrew runs one command at a time; a second one waits on the first's
    /// lock or fails on it.
    private func ensureIdle() -> Bool {
        if isBusy { showsBusyAlert = true }
        return !isBusy
    }

    private func loadInfo() {
        infoTask?.cancel()
        info = nil
        guard let name = selectedName, showsFormulaPanel, let brew = homebrew.brew else { return }
        infoTask = Task {
            // Arrowing through the list should not start a command per row.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let json = await brew.output(["info", "--json=v2", "--formula", name]).text
            guard !Task.isCancelled else { return }
            info = FormulaInfo(json: json)
        }
    }
}

/// Lets the import panel pick only a file named like the one Homebrew writes.
private final class BrewfileFilter: NSObject, NSOpenSavePanelDelegate {

    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        url.hasDirectoryPath || url.lastPathComponent == BundleJob.fileName
    }
}
