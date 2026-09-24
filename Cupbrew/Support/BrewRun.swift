import Foundation
import Observation

/// One `brew` command whose output is shown to the user as it arrives.
@Observable @MainActor
final class BrewRun {

    private(set) var log = ""
    private(set) var isRunning = false

    @discardableResult
    func start(_ arguments: [String], with brew: Brew) async -> Int32 {
        isRunning = true
        defer { isRunning = false }
        return await brew.run(arguments) { [weak self] text in
            self?.log += text
        }
    }

    func clear() {
        log = ""
    }
}
