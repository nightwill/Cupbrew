import Foundation

/// Where a formula stands on this Mac.
enum FormulaStatus {
    case notInstalled
    case installed
    case outdated

    var title: LocalizedStringResource {
        switch self {
        case .notInstalled: "Not Installed"
        case .installed: "Installed"
        case .outdated: "Update Available"
        }
    }
}
