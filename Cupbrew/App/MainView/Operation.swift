import Foundation

/// A command that changes what is installed, run in a sheet over the window.
@MainActor
struct Operation: Identifiable {

    enum Kind {
        case install
        case uninstall
        case upgrade
        case upgradeAll
        case tap
        case untap
        case cleanup
    }

    let id = UUID()
    let kind: Kind
    var names: [String] = []
    var options: [String] = []
    let run = BrewRun()

    var title: String {
        switch kind {
        case .install: String(localized: "Installing Formula:")
        case .uninstall: String(localized: "Uninstalling Formula:")
        case .upgrade, .upgradeAll: String(localized: "Updating Formula:")
        case .tap: String(localized: "Tapping Repo:")
        case .untap: String(localized: "Untapping Repo:")
        case .cleanup: String(localized: "Running Cleanup…")
        }
    }

    /// What the title is about, shown after it.
    var subject: String {
        switch kind {
        case .upgradeAll: String(localized: "All Outdated Formulae")
        case .cleanup: ""
        default: names.joined(separator: ", ")
        }
    }

    var arguments: [String] {
        switch kind {
        case .install: ["install"] + names + options
        case .uninstall: ["uninstall"] + names
        case .upgrade, .upgradeAll: ["upgrade"] + names
        case .tap: ["tap"] + names
        case .untap: ["untap"] + names
        case .cleanup: ["cleanup"]
        }
    }

    /// Cleanup only frees disk space; everything else changes the lists.
    var changesFormulae: Bool {
        kind != .cleanup
    }
}
