import Foundation

/// What `brew info --json=v2` knows about one formula.
struct FormulaInfo: Decodable, Sendable {

    struct Versions: Decodable, Sendable {
        let stable: String?
    }

    struct Option: Decodable, Hashable, Identifiable, Sendable {
        let option: String
        let description: String

        var id: String { option }
    }

    struct Installation: Decodable, Sendable {
        let version: String
    }

    let name: String
    let desc: String?
    let homepage: String?
    let versions: Versions
    let dependencies: [String]
    let conflictsWith: [String]
    let options: [Option]
    let installed: [Installation]

    /// Decodes the first formula of a `brew info --json=v2` answer.
    init?(json: String) {
        struct Answer: Decodable { let formulae: [FormulaInfo] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let answer = try? decoder.decode(Answer.self, from: Data(json.utf8)),
              let formula = answer.formulae.first else { return nil }
        self = formula
    }

    /// The keg of the newest installed version, `nil` when none is installed.
    func installPath(cellar: String) -> String? {
        installed.last.map { "\(cellar)/\(name)/\($0.version)" }
    }
}
