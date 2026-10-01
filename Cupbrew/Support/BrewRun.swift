import Foundation
import Observation

/// One `brew` command whose output is shown to the user as it arrives.
@Observable @MainActor
final class BrewRun {

    /// Everything shown so far, each command closed by a line saying how it
    /// ended.
    private(set) var log = ""

    /// What the last command printed, without that closing line.
    private(set) var output = ""

    private(set) var isRunning = false

    @discardableResult
    func start(_ arguments: [String], with brew: Brew) async -> Int32 {
        isRunning = true
        defer { isRunning = false }
        output = ""
        let status = await brew.run(arguments) { [weak self] text in
            self?.log += text
            self?.output += text
        }
        // Without the status a failed command looks finished like any other:
        // the output alone does not always say it failed.
        let date = Date.now.formatted(date: .numeric, time: .shortened)
        // swiftlint:disable non_localized_string
        if !log.isEmpty, !log.hasSuffix("\n") { log += "\n" }
        log += String(localized: "Task finished: (\(status)) at \(date)!") + "\n"
        // swiftlint:enable non_localized_string
        return status
    }

    func clear() {
        log = ""
        output = ""
    }
}
