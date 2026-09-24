import SwiftUI

/// The formula items, shared by the Formula menu and the rows' context menu.
struct FormulaMenu: View {

    let browser: Browser
    let names: Set<String>

    /// The menu bar carries the shortcuts; a context menu is already under
    /// the pointer and needs none.
    var isMainMenu = false

    var body: some View {
        Button("Install Formula") { browser.install(names) }
            .keyboardShortcut(isMainMenu ? KeyboardShortcut(.return, modifiers: []) : nil)
            .disabled(!browser.canInstall(names) || !takesPlainKeys)
            .modifierKeyAlternate(.option) {
                Button("Install Formula with Options…") { browser.installWithOptions(names) }
                    .disabled(!browser.canInstall(names))
            }
        Button("Uninstall Formula") { browser.uninstall(names) }
            .keyboardShortcut(isMainMenu ? KeyboardShortcut(.delete, modifiers: []) : nil)
            .disabled(!browser.canUninstall(names) || !takesPlainKeys)
        Button("Update Formula") { browser.upgrade(names) }
            .keyboardShortcut(isMainMenu ? KeyboardShortcut("r") : nil)
            .disabled(names.count != 1 || !browser.canUpgrade(names))

        Divider()

        Button("More Information") { browser.showPopover(.info, for: names) }
            .keyboardShortcut(isMainMenu ? KeyboardShortcut("i") : nil)
            .disabled(!browser.canShowInfo(names))
        Button("List Installed Dependents") { browser.showPopover(.installedDependents, for: names) }
            .disabled(!browser.canShowInfo(names))
            .modifierKeyAlternate(.option) {
                Button("List All Dependents") { browser.showPopover(.allDependents, for: names) }
                    .disabled(!browser.canShowInfo(names))
            }
        Button("Formula Website") { browser.openWebsite(for: names) }
            .keyboardShortcut(isMainMenu ? KeyboardShortcut("w", modifiers: [.command, .option]) : nil)
            .disabled(browser.website(for: names) == nil)
    }

    /// Return and Delete without a modifier are the typing keys of the search
    /// field too, so the menu claims them only while the rows have focus.
    private var takesPlainKeys: Bool {
        !isMainMenu || browser.isTableFocused
    }
}
