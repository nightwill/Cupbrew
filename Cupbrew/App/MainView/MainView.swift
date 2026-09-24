import SwiftUI

/// The one window: lists in the sidebar, their rows, and the panel below.
struct MainView: View {

    let homebrew: Homebrew

    @State private var browser: Browser
    @FocusState private var isSearchFocused: Bool

    init(homebrew: Homebrew) {
        self.homebrew = homebrew
        _browser = State(initialValue: Browser(homebrew: homebrew))
    }

    var body: some View {
        @Bindable var browser = browser

        NavigationSplitView {
            SidebarView(browser: browser)
                .navigationSplitViewColumnWidth(min: 160, ideal: 190)
                .toolbar {
                    ToolbarItem {
                        Button("Update Homebrew", systemImage: "globe", action: browser.updateHomebrew)
                            .help("Update Homebrew")
                            .disabled(!browser.isReady)
                    }
                }
        } detail: {
            detail
                .safeAreaInset(edge: .bottom, spacing: 0) { statusBar }
                .toolbar { actionButtons }
        }
        .searchable(text: $browser.searchText, placement: .toolbar, prompt: Text("Search Formulae"))
        .searchFocused($isSearchFocused)
        .onChange(of: browser.searchFocusRequest) { isSearchFocused = true }
        .overlay { cover }
        .frame(minWidth: 570, minHeight: 342)
        .focusedSceneValue(browser)
        .task { await homebrew.start() }
        .alert(
            browser.confirmation?.title ?? "",
            isPresented: isPresent($browser.confirmation),
            presenting: browser.confirmation
        ) { confirmation in
            Button(confirmation.confirmTitle, action: confirmation.action)
            Button("Cancel", role: .cancel) {}
        } message: { confirmation in
            Text(confirmation.message)
        }
        .alert("Tapping Repository", isPresented: $browser.isAskingForTap) {
            TextField("user/repo", text: $browser.tapName)
            Button("OK", action: browser.tap)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What repository would you like to tap?")
        }
        .alert("Active background task!", isPresented: $browser.showsBusyAlert) {
            Button("OK") {}
        } message: {
            Text("Sorry, a background task is already running. You can't perform two tasks at the same time.")
        }
        .alert("Error", isPresented: .constant(homebrew.state == .missing)) {
            Button("Homebrew Website") {
                // swiftlint:disable:next force_unwrapping
                NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Homebrew was not found in your system. Please install Homebrew before using Cupbrew. You can click the button below to open Homebrew's website.")
        }
        .sheet(item: $browser.operation) { OperationView(operation: $0) }
        .sheet(item: $browser.optionsRequest) { FormulaOptionsView(name: $0.name, browser: browser) }
        .sheet(item: $browser.bundleJob) { BundleView(job: $0) }
    }

    @ViewBuilder private var detail: some View {
        switch browser.sidebar {
        case .doctor:
            ToolView(
                title: "Homebrew Doctor",
                buttonTitle: "Run Doctor",
                run: browser.doctor,
                isEnabled: browser.isReady,
                action: browser.runDoctor
            )
        case .update:
            ToolView(
                title: "Homebrew Updater",
                buttonTitle: "Update Homebrew",
                run: browser.update,
                isEnabled: browser.isReady,
                action: browser.updateHomebrew
            )
        default:
            if browser.showsFormulaPanel {
                VSplitView {
                    FormulaTableView(browser: browser)
                        .frame(minHeight: 100)
                    SelectedFormulaView(browser: browser)
                        .frame(minHeight: 90, idealHeight: 120, maxHeight: 200)
                }
            } else {
                FormulaTableView(browser: browser)
            }
        }
    }

    private var statusBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                if homebrew.isReloading || browser.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                Text(browser.isReady ? browser.footer : String(localized: "Loading..."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
            .padding(.vertical, 3)
            .frame(minHeight: 20)
        }
        .background(.bar)
    }

    @ToolbarContentBuilder private var actionButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if let action = actionButton {
                Button(action.title, systemImage: action.symbol, action: browser.performToolbarAction)
                    .help(action.title)
            }
            if showsInfoButton {
                Button("More Information", systemImage: "info.circle.fill") {
                    browser.showPopover(.info, for: browser.selection)
                }
                .help("More Information")
            }
        }
    }

    @ViewBuilder private var cover: some View {
        switch homebrew.state {
        case .loading: LoadingView()
        case .missing: MissingBrewView()
        case .ready: EmptyView()
        }
    }

    private var actionButton: (title: LocalizedStringKey, symbol: String)? {
        guard browser.isReady else { return nil }
        switch browser.toolbarAction {
        case .none: return nil
        case .install: return (title: "Install Formula", symbol: "plus.circle.fill")
        case .uninstall: return (title: "Uninstall Formula", symbol: "xmark.circle.fill")
        case .tap: return (title: "Tap Repository", symbol: "plus.circle.fill")
        case .untap: return (title: "Untap Repository", symbol: "xmark.circle.fill")
        case .upgradeOne: return (title: "Update Formula", symbol: "arrow.triangle.2.circlepath.circle.fill")
        case .upgradeMany: return (title: "Update Selected", symbol: "arrow.triangle.2.circlepath.circle.fill")
        }
    }

    private var showsInfoButton: Bool {
        guard browser.isReady else { return false }
        switch browser.toolbarAction {
        case .install, .uninstall, .upgradeOne: return true
        case .none, .tap, .untap, .upgradeMany: return false
        }
    }

    private func isPresent<Value>(_ binding: Binding<Value?>) -> Binding<Bool> {
        Binding {
            binding.wrappedValue != nil
        } set: { isPresented in
            if !isPresented { binding.wrappedValue = nil }
        }
    }
}
