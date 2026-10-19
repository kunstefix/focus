import Foundation

/// Opens the app at login through a LaunchAgent. SMAppService.mainApp is the
/// modern way, but it isn't reliable for an ad-hoc signed app.
enum LoginItem {
    private static let label = "io.github.kunstefix.focus.app"

    private static var plist: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plist.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard enabled else {
            try? FileManager.default.removeItem(at: plist)
            return
        }
        let contents: [String: Any] = [
            "Label": label,
            "ProgramArguments": [Bundle.main.executablePath ?? "", AppDelegate.loginArgument],
            "RunAtLoad": true,
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: contents, format: .xml, options: 0)
        try FileManager.default.createDirectory(at: plist.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: plist)
    }
}
