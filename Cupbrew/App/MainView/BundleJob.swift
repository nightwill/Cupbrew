import Foundation
import Observation

/// Writing the installed formulae to a Brewfile, or installing from one.
@Observable @MainActor
final class BundleJob: Identifiable {

    enum Kind {
        case export
        case `import`
    }

    /// The only name Homebrew Bundle looks for by default.
    static let fileName = "Brewfile" // swiftlint:disable:this non_localized_string

    let kind: Kind
    let file: URL
    let run = BrewRun()

    private(set) var isFinished = false

    /// Why the export failed, `nil` while it runs or once it succeeded.
    private(set) var error: String?

    init(kind: Kind, file: URL) {
        self.kind = kind
        self.file = file
    }

    func start(with brew: Brew) async {
        let arguments = switch kind {
        case .export: ["bundle", "dump", "--force", "--file=\(file.path)"]
        case .import: ["bundle", "--file=\(file.path)"]
        }
        let status = await run.start(arguments, with: brew)
        if status != 0 {
            error = Brew.failure(in: run.output, status: status)
        }
        isFinished = true
    }
}
