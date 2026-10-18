import FocusCore
import Foundation

enum Paths {
    // Must match src/common.sh
    static let libDir = "/Library/PrivilegedHelperTools/com.klemen.focus"
    static let configFile = libDir + "/config"
    static let deadlineFile = "/var/run/focus.deadline"
    static let logFile = "/var/db/focus/breaks.log"
    // Before the app, install.sh passed the repo's sites.txt to this daemon
    static let daemonPlist = "/Library/LaunchDaemons/com.klemen.focus.plist"

    static var sitesFile: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Focus/sites.txt")
    }

    /// The copies of src/*.sh in the app bundle, or the repo's src/ under `swift run`
    static var scriptsDir: URL {
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("scripts"),
           FileManager.default.fileExists(atPath: bundled.path) {
            return bundled
        }
        return URL(fileURLWithPath: #filePath)  // app/Sources/Focus/FocusStatus.swift
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("src")
    }

    /// Next to scripts/ in the bundle, in the repo root under `swift run`
    static var exampleSitesFile: URL {
        scriptsDir.deletingLastPathComponent().appendingPathComponent("sites.example.txt")
    }
}

/// What the menu shows, re-read every second from files the scripts write.
/// All of them are world-readable, so this needs no root.
@MainActor
final class FocusStatus: ObservableObject {
    @Published private(set) var installed = false
    @Published private(set) var breakEnd: Date?
    @Published private(set) var todayTotal: TimeInterval = 0
    @Published private(set) var busy = false
    @Published var error: String?

    private var timer: Timer?

    init() {
        refresh()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func refresh() {
        let now = Date()
        installed = FileManager.default.isExecutableFile(atPath: Paths.libDir + "/focus.sh")
        breakEnd = Self.readDeadline().flatMap { $0 > now ? $0 : nil }
        let log = (try? String(contentsOfFile: Paths.logFile, encoding: .utf8)) ?? ""
        todayTotal = BreakLog.total(on: now, log: log, now: now)
    }

    func startBreak(minutes: Int) {
        perform { try await Privileged.startBreak(minutes: minutes) }
    }

    func endBreak() {
        perform { try await Privileged.focus() }
    }

    func install() {
        perform {
            try SitesFile.createIfMissing()
            try await Privileged.install(sitesFile: Paths.sitesFile.path)
        }
    }

    func uninstall() {
        perform { try await Privileged.uninstall() }
    }

    /// During a break the new list applies when the break ends
    func saveSites(_ text: String) {
        perform { [installed, breakEnd] in
            try SitesFile.write(text)
            if installed && breakEnd == nil {
                try await Privileged.focus()
            }
        }
    }

    private func perform(_ action: @escaping () async throws -> Void) {
        busy = true
        error = nil
        Task {
            do {
                try await action()
            } catch is Privileged.Cancelled {
                // The user closed the password prompt
            } catch {
                self.error = error.localizedDescription
            }
            busy = false
            refresh()
        }
    }

    /// unfocus.sh writes "<start> <deadline>" and focus.sh removes the file
    private static func readDeadline() -> Date? {
        guard let text = try? String(contentsOfFile: Paths.deadlineFile, encoding: .utf8),
              let deadline = text.split(separator: " ").last.flatMap({ TimeInterval($0.trimmingCharacters(in: .whitespacesAndNewlines)) })
        else { return nil }
        return Date(timeIntervalSince1970: deadline)
    }
}
