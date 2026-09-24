import SwiftUI

/// The menu bar: formula and tool commands, and the lists in the View menu.
struct CupbrewCommands: Commands {

    @FocusedValue(Browser.self) private var browser

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu(Text("Formula")) {
            if let browser {
                FormulaMenu(browser: browser, names: browser.selection, isMainMenu: true)

                Divider()

                Button("Upgrade Selected Formulae") { browser.upgrade(browser.selection) }
                    .keyboardShortcut("u")
                    .disabled(!browser.canUpgrade(browser.selection))
                    .modifierKeyAlternate(.option) {
                        Button("Upgrade All Formulae") { browser.upgradeAll() }
                            .disabled(!browser.canUpgradeAll)
                    }

                Divider()

                Button("Search for Formula") { browser.focusSearch() }
                    .keyboardShortcut("f")
                    .disabled(!browser.isReady)
            }
        }

        CommandMenu(Text("Tools")) {
            Group {
                Button("Brew Cleanup…") { browser?.cleanup() }
                Divider()
                Button("Export Brew Installation…") { browser?.exportBundle() }
                Button("Import Brew Installation…") { browser?.importBundle() }
            }
            .disabled(browser?.isReady != true)
        }

        CommandGroup(before: .sidebar) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                Button(String(localized: item.menuTitle)) { browser?.select(item) }
                    .keyboardShortcut(item.shortcut)
                    .disabled(browser?.isReady != true)
            }
            Divider()
        }
    }
}
