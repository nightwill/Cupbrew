import Foundation

/// What the popover next to the rows shows about one formula.
struct FormulaPopover: Identifiable {

    enum Kind {
        case info
        case installedDependents
        case allDependents
    }

    let kind: Kind
    let name: String

    var id: String { "\(kind)-\(name)" }

    var title: String {
        switch kind {
        case .info: String(localized: "Information for Formula: \(name)")
        case .installedDependents: String(localized: "Installed Dependents of Formula: \(name)")
        case .allDependents: String(localized: "All Dependents of Formula: \(name)")
        }
    }

    var arguments: [String] {
        switch kind {
        case .info: ["info", name]
        case .installedDependents: ["uses", "--installed", name]
        case .allDependents: ["uses", name]
        }
    }
}
