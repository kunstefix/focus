import Foundation

/// Runs the scripts in src/, which do all the root work.
enum Privileged {
    struct Failure: LocalizedError {
        let errorDescription: String?
    }

    struct Cancelled: Error {}

    static func startBreak(minutes: Int) async throws {
        // Under osascript SUDO_USER isn't set; unfocus.sh needs the user to restart their browser as
        try await runAsAdmin("FOCUS_USER=\(quote(NSUserName())) \(quote(Paths.libDir + "/unfocus.sh")) -m \(minutes)")
    }

    /// Needs no password: install.sh adds a sudoers rule for exactly this command
    static func focus() async throws {
        try await run("/usr/bin/sudo", ["-n", Paths.libDir + "/focus.sh"])
    }

    static func install(sitesFile: String) async throws {
        try await runAsAdmin("\(quote(Paths.scriptsDir.appendingPathComponent("install.sh").path)) \(quote(sitesFile))")
    }

    static func uninstall() async throws {
        try await runAsAdmin(quote(Paths.scriptsDir.appendingPathComponent("uninstall.sh").path))
    }

    /// Runs a shell command as root after the macOS admin password prompt.
    /// The prompt's 5-minute grace period is per process and every call starts
    /// a new osascript, so it asks every time. That friction is deliberate.
    private static func runAsAdmin(_ command: String) async throws {
        do {
            try await run("/usr/bin/osascript", [
                "-e", "on run argv",
                "-e", "do shell script (item 1 of argv) with administrator privileges",
                "-e", "end run",
                command,
            ])
        } catch let failure as Failure where failure.errorDescription?.contains("(-128)") == true {
            throw Cancelled()
        }
    }

    private static func run(_ executable: String, _ arguments: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        let stderr = Pipe()
        process.standardError = stderr

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { process in
                if process.terminationStatus == 0 {
                    continuation.resume()
                    return
                }
                let output = String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(throwing: Failure(errorDescription: output.isEmpty ? "\(executable) failed" : output))
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
