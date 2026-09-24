import Foundation

/// The `brew` executable and the one way its commands are run.
///
/// Commands run in a process of their own, never through a shell: arguments
/// are handed over as they are, so a tap or a path with a space in it reaches
/// Homebrew intact instead of being split by a shell on the way.
struct Brew: Sendable {

    let executable: URL

    /// Finds Homebrew where it installs itself, and failing that asks the
    /// user's login shell, which is the only place a custom prefix is known.
    static func locate() async -> Brew? {
        let fileManager = FileManager.default
        let candidates = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew", "/home/linuxbrew/.linuxbrew/bin/brew"]
        if let path = candidates.first(where: fileManager.isExecutableFile(atPath:)) {
            return Brew(executable: URL(filePath: path))
        }
        guard let path = await loginShellBrewPath(), fileManager.isExecutableFile(atPath: path) else { return nil }
        return Brew(executable: URL(filePath: path))
    }

    /// Runs `brew` with `arguments` and hands its output to `receive` piece by
    /// piece, on the main actor and in the order it was printed.
    ///
    /// Returns the exit status; a command that could not be started reports
    /// why through `receive` and comes back as -1.
    @discardableResult
    func run(
        _ arguments: [String],
        includingErrors: Bool = true,
        receive: @escaping @MainActor (String) -> Void
    ) async -> Int32 {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let status = Self.runBlocking(executable, arguments, includingErrors: includingErrors) { text in
                    // The main queue is serial, and the continuation below
                    // resumes on it too, so every piece arrives before the
                    // caller learns the command is over.
                    DispatchQueue.main.async { MainActor.assumeIsolated { receive(text) } }
                }
                DispatchQueue.main.async { continuation.resume(returning: status) }
            }
        }
    }

    /// Runs `brew` with `arguments` to the end and returns what it printed to
    /// standard output. Standard error is dropped: Homebrew reports progress
    /// there, and it would break the JSON a caller is about to decode.
    func output(_ arguments: [String]) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var output = ""
                _ = Self.runBlocking(executable, arguments, includingErrors: false) { output += $0 }
                continuation.resume(returning: output)
            }
        }
    }

    /// Stops every command still running, so none outlives the app.
    static func terminateAll() {
        running.withLock { $0.forEach { $0.terminate() } }
    }

    private static let running = Locked<Set<Process>>([])

    private static func runBlocking(
        _ executable: URL,
        _ arguments: [String],
        includingErrors: Bool,
        receive: (String) -> Void
    ) -> Int32 {
        let process = Process()
        // One pipe for both streams: two would have to be drained at once, or
        // the unread one fills up and stops the command halfway.
        let pipe = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment(for: executable)
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        // A command left holding our standard input could wait forever on an
        // answer nobody is going to type.
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = pipe
        process.standardError = includingErrors ? pipe : FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            receive(error.localizedDescription + "\n")
            return -1
        }
        running.withLock { _ = $0.insert(process) }
        defer { running.withLock { _ = $0.remove(process) } }

        var decoder = TextDecoder()
        let handle = pipe.fileHandleForReading
        while case let data = handle.availableData, !data.isEmpty {
            if let text = decoder.decode(data) { receive(text) }
        }
        if let text = decoder.flush() { receive(text) }
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// An app opened from Finder inherits launchd's bare `PATH`, where the
    /// tools Homebrew calls out to are missing, so its own `bin` goes first.
    /// Its `sbin` goes along: `brew doctor` warns when that is missing from
    /// `PATH`, which in a terminal set up for Homebrew it never is.
    private static func environment(for executable: URL) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let bin = executable.deletingLastPathComponent()
        let sbin = bin.deletingLastPathComponent().appending(path: "sbin")
        environment["PATH"] = [bin.path, sbin.path, environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"]
            .joined(separator: ":")
        return environment
    }

    private static func loginShellBrewPath() async -> String? {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let brew = Brew(executable: URL(filePath: shell))
        // A profile may print a greeting, so the answer is fenced between two
        // control characters nothing else prints and cut out of the noise.
        // swiftlint:disable:next non_localized_string
        let output = await brew.output(["-l", "-c", "printf '\\1%s\\2' \"$(command -v brew)\""])
        guard let opening = output.firstIndex(of: "\u{01}"),
              let closing = output[opening...].firstIndex(of: "\u{02}") else { return nil }
        let path = String(output[output.index(after: opening)..<closing])
        return path.isEmpty ? nil : path
    }
}

/// Turns a byte stream into text without cutting a character in two: a read
/// can end in the middle of a multi-byte character, so only what precedes the
/// last line break is decoded and the rest waits for the next read.
private struct TextDecoder {

    private var pending = Data()

    mutating func decode(_ data: Data) -> String? {
        pending.append(data)
        guard let lastBreak = pending.lastIndex(where: { $0 == 0x0A || $0 == 0x0D }) else { return nil }
        let complete = pending[...lastBreak]
        pending = Data(pending[pending.index(after: lastBreak)...])
        return Self.string(complete)
    }

    /// Latin-1 decodes any bytes at all, so output that is not UTF-8 still
    /// shows up rather than vanishing.
    private static func string(_ data: Data) -> String {
        String(bytes: data, encoding: .utf8) ?? String(bytes: data, encoding: .isoLatin1) ?? ""
    }

    mutating func flush() -> String? {
        defer { pending = Data() }
        return pending.isEmpty ? nil : Self.string(pending)
    }
}

/// A value shared between threads behind a lock.
private final class Locked<Value>: @unchecked Sendable {

    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) { self.value = value }

    func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}
