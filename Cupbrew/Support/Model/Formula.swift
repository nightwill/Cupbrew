import Foundation

/// A row of one of the lists: a formula, or a tapped repository, which the
/// lists show the same way.
struct Formula: Identifiable, Hashable, Sendable {

    let name: String
    var version: String?
    var latestVersion: String?

    var id: String { name }

    /// The name Homebrew lists an installed formula under: a formula from a
    /// tap is known everywhere else by its full `user/tap/name`.
    var shortName: String {
        name.split(separator: "/").last.map(String.init) ?? name
    }
}
