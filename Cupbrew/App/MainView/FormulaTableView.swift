import SwiftUI

/// The rows of the list chosen in the sidebar, with the columns that list has.
struct FormulaTableView: View {

    @Bindable var browser: Browser
    @FocusState private var isFocused: Bool

    var body: some View {
        table
            .focused($isFocused)
            .onChange(of: isFocused) { browser.isTableFocused = isFocused }
            .contextMenu(forSelectionType: String.self) { names in
                FormulaMenu(browser: browser, names: names)
            }
            .onKeyPress(.space) {
                guard browser.canShowInfo(browser.selection) else { return .ignored }
                browser.showPopover(.info, for: browser.selection)
                return .handled
            }
            .popover(item: $browser.popover, arrowEdge: .trailing) { popover in
                FormulaPopoverView(popover: popover, brew: browser.homebrew.brew)
            }
    }

    @ViewBuilder private var table: some View {
        let rows = browser.rows
        if browser.isSearching {
            Table(rows, selection: singleSelection) { nameColumn; statusColumn }
        } else {
            switch browser.sidebar {
            case .installed:
                Table(rows, selection: singleSelection) { nameColumn; versionColumn }
            case .outdated:
                Table(rows, selection: $browser.selection) { nameColumn; versionColumn; latestVersionColumn }
            case .all:
                Table(rows, selection: singleSelection) { nameColumn; statusColumn }
            case .leaves, .repositories, .doctor, .update:
                Table(rows, selection: singleSelection) { nameColumn }
            }
        }
    }

    private var nameColumn: some TableColumnContent<Formula, Never> {
        TableColumn("Name", value: \.name)
    }

    private var versionColumn: some TableColumnContent<Formula, Never> {
        TableColumn("Version") { Text($0.version ?? "") }
    }

    private var latestVersionColumn: some TableColumnContent<Formula, Never> {
        TableColumn("Latest Version") { Text($0.latestVersion ?? "") }
    }

    private var statusColumn: some TableColumnContent<Formula, Never> {
        TableColumn("Status") { Text(browser.homebrew.status(of: $0.name).title) }
    }

    /// Every list but Outdated picks one row at a time.
    private var singleSelection: Binding<String?> {
        Binding {
            browser.selectedName
        } set: { name in
            browser.selection = name.map { [$0] } ?? []
        }
    }
}
