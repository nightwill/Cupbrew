import SwiftUI

/// A row of the sidebar, and what the window shows for it.
enum SidebarItem: Hashable, CaseIterable {
    case installed
    case outdated
    case all
    case leaves
    case repositories
    case doctor
    case update

    static let formulae: [SidebarItem] = [.installed, .outdated, .all, .leaves, .repositories]
    static let tools: [SidebarItem] = [.doctor, .update]

    /// The Homebrew list the rows come from; tools have none.
    var list: Homebrew.List? {
        switch self {
        case .installed: .installed
        case .outdated: .outdated
        case .all: .all
        case .leaves: .leaves
        case .repositories: .repositories
        case .doctor, .update: nil
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .installed: "Installed"
        case .outdated: "Outdated"
        case .all: "All Formulae"
        case .leaves: "Leaves"
        case .repositories: "Repositories"
        case .doctor: "Doctor"
        case .update: "Update"
        }
    }

    /// The title of its item in the View menu.
    var menuTitle: LocalizedStringResource {
        switch self {
        case .installed: "Installed Formulae"
        case .outdated: "Outdated Formulae"
        default: title
        }
    }

    var symbol: String {
        switch self {
        case .installed: "checkmark.square"
        case .outdated: "clock.arrow.circlepath"
        case .all: "books.vertical"
        case .leaves: "leaf"
        case .repositories: "building.columns"
        case .doctor: "stethoscope"
        case .update: "arrow.triangle.2.circlepath.circle"
        }
    }

    var shortcut: KeyEquivalent {
        let index = Self.allCases.firstIndex(of: self) ?? 0
        return KeyEquivalent(Character(String(index + 1)))
    }

    var footer: LocalizedStringResource {
        switch self {
        case .installed: "These are the formulae already installed in your system."
        case .outdated: "These formulae are already installed, but have an update available."
        case .all: "These are all the formulae available for installation with Homebrew."
        case .leaves: "These formulae are not dependencies of any other formulae."
        case .repositories: "These are the repositories you have tapped."
        case .doctor: "The doctor is a Homebrew feature that detects the most common causes of errors."
        case .update: "Updating Homebrew means fetching the latest info about the available formulae."
        }
    }

    var isTool: Bool {
        Self.tools.contains(self)
    }
}
