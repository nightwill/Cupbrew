import Foundation
import Observation

/// What Homebrew has installed and can install, reloaded from its commands.
@Observable @MainActor
final class Homebrew {

    enum State {
        case loading
        case missing
        case ready
    }

    private(set) var state = State.loading
    private(set) var brew: Brew?
    private(set) var cellar: String?

    private(set) var installed: [Formula] = []
    private(set) var outdated: [Formula] = []
    private(set) var all: [Formula] = []
    private(set) var leaves: [Formula] = []
    private(set) var repositories: [Formula] = []

    private(set) var isReloading = false

    private var installedNames: Set<String> = []
    private var outdatedNames: Set<String> = []

    func start() async {
        guard state == .loading, brew == nil else { return }
        guard let brew = await Brew.locate() else {
            state = .missing
            return
        }
        self.brew = brew
        cellar = await brew.output(["--cellar"]).trimmingCharacters(in: .whitespacesAndNewlines)
        await reload()
    }

    /// Reads every list again. Called at launch and after anything that
    /// installs, removes or taps.
    func reload() async {
        guard let brew else { return }
        isReloading = true
        defer { isReloading = false }

        async let installedOutput = brew.output(["list", "--formula", "--versions"])
        async let outdatedOutput = brew.output(["outdated", "--formula", "--json=v2"])
        async let allOutput = brew.output(["formulae"])
        async let leavesOutput = brew.output(["leaves"])
        async let tapOutput = brew.output(["tap"])

        installed = await Self.lines(of: installedOutput).map { line in
            // `name 1.0 1.1`: several versions are installed side by side,
            // the last is the newest.
            let words = line.split(separator: " ").map(String.init)
            return Formula(name: words[0], version: words.count > 1 ? words.last : nil)
        }
        outdated = Self.outdated(from: await outdatedOutput)
        all = await Self.lines(of: allOutput).map { Formula(name: $0) }
        leaves = await Self.lines(of: leavesOutput).map { Formula(name: $0) }
        repositories = await Self.lines(of: tapOutput).map { Formula(name: $0) }

        installedNames = Set(installed.map(\.name))
        outdatedNames = Set(outdated.map(\.name))
        state = .ready
    }

    func status(of name: String) -> FormulaStatus {
        let shortName = Formula(name: name).shortName
        if outdatedNames.contains(shortName) { return .outdated }
        return installedNames.contains(shortName) ? .installed : .notInstalled
    }

    private static func lines(of output: String) -> [String] {
        output.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func outdated(from json: String) -> [Formula] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let answer = try? decoder.decode(Outdated.self, from: Data(json.utf8)) else { return [] }
        return answer.formulae.map {
            Formula(name: $0.name, version: $0.installedVersions.last, latestVersion: $0.currentVersion)
        }
    }
}
