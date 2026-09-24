import Foundation

/// The answer of `brew outdated --json=v2`.
struct Outdated: Decodable, Sendable {

    struct Entry: Decodable, Sendable {
        let name: String
        let installedVersions: [String]
        let currentVersion: String
    }

    let formulae: [Entry]
}
