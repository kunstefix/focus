import FocusCore
import Foundation

enum Paths {
    // Must match src/common.sh
    static let libDir = "/Library/PrivilegedHelperTools/io.github.kunstefix.focus"
    static let configFile = libDir + "/config"
    static let deadlineFile = "/var/run/focus.deadline"
    static let logFile = "/var/db/focus/breaks.log"
    // Before the app, install.sh passed the repo's sites.txt to this daemon
    static let daemonPlist = "/Library/LaunchDaemons/io.github.kunstefix.focus.plist"
    // Must match install.sh; lets "End break now" run focus.sh without a password
    static let sudoersFile = "/etc/sudoers.d/focus"

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
    @Published private(set) var breakStart: Date?
    @Published private(set) var breakEnd: Date?
    @Published private(set) var todayBreaks: [BreakLog.Interval] = []
    @Published private(set) var siteCount = 0
    @Published private(set) var busy = false
    @Published var error: String?

    private var timer: Timer?

    var todayTotal: TimeInterval {
        todayBreaks.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

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
        // focusd.sh is the newest script, so older installs show Install again.
        // Without the sudoers rule, breaks can't be ended early, so that counts too.
        installed = FileManager.default.isExecutableFile(atPath: Paths.libDir + "/focusd.sh")
            && FileManager.default.fileExists(atPath: Paths.sudoersFile)
        let deadline = Self.readDeadline().flatMap { $0.end > now ? $0 : nil }
        breakStart = deadline?.start
        breakEnd = deadline?.end
        let log = (try? String(contentsOfFile: Paths.logFile, encoding: .utf8)) ?? ""
        todayBreaks = BreakLog.intervals(on: now, log: log, now: now)
        siteCount = SitesList(text: SitesFile.read()).domains.count
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
        siteCount = SitesList(text: text).domains.count
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

    /// unfocus.sh writes "<start> <deadline> <user>" and focus.sh removes the file
    private static func readDeadline() -> (start: Date, end: Date)? {
        guard let text = try? String(contentsOfFile: Paths.deadlineFile, encoding: .utf8) else { return nil }
        let fields = text.split(whereSeparator: \.isWhitespace)
        guard fields.count >= 2, let start = TimeInterval(fields[0]), let end = TimeInterval(fields[1]) else { return nil }
        return (Date(timeIntervalSince1970: start), Date(timeIntervalSince1970: end))
    }

    #if DEBUG
    /// Fixed state for rendering the views without the scripts installed
    static func preview(installed: Bool = true, breakMinutes: (total: Double, left: Double)? = nil,
                        todayBreaks: [(hour: Double, minutes: Double)] = [], siteCount: Int = 6,
                        error: String? = nil) -> FocusStatus {
        let status = FocusStatus()
        status.timer?.invalidate()
        let now = Date()
        status.installed = installed
        if let breakMinutes {
            status.breakEnd = now.addingTimeInterval(breakMinutes.left * 60)
            status.breakStart = status.breakEnd?.addingTimeInterval(-breakMinutes.total * 60)
        } else {
            status.breakStart = nil
            status.breakEnd = nil
        }
        let midnight = Calendar.current.startOfDay(for: now)
        status.todayBreaks = todayBreaks.map {
            let start = midnight.addingTimeInterval($0.hour * 3600)
            return BreakLog.Interval(start: start, end: start.addingTimeInterval($0.minutes * 60))
        }
        status.siteCount = siteCount
        status.error = error
        return status
    }
    #endif
}
