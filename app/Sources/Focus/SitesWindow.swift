import SwiftUI

enum SitesFile {
    static func read() -> String {
        (try? String(contentsOf: Paths.sitesFile, encoding: .utf8)) ?? ""
    }

    static func write(_ text: String) throws {
        try createDirectory()
        try text.write(to: Paths.sitesFile, atomically: true, encoding: .utf8)
    }

    /// Starts from the list an earlier install used, else from the example
    static func createIfMissing() throws {
        guard !FileManager.default.fileExists(atPath: Paths.sitesFile.path) else { return }
        try createDirectory()
        let source = previousSitesFile() ?? Paths.exampleSitesFile
        try FileManager.default.copyItem(at: source, to: Paths.sitesFile)
    }

    private static func createDirectory() throws {
        try FileManager.default.createDirectory(at: Paths.sitesFile.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
    }

    private static func previousSitesFile() -> URL? {
        var candidates: [String] = []
        // install.sh writes SITES_FILE=<path quoted with printf %q>
        if let config = try? String(contentsOfFile: Paths.configFile, encoding: .utf8),
           let line = config.split(separator: "\n").first(where: { $0.hasPrefix("SITES_FILE=") }) {
            let quoted = String(line.dropFirst("SITES_FILE=".count))
            candidates.append(quoted.replacingOccurrences(of: #"\\(.)"#, with: "$1", options: .regularExpression))
        }
        // Before the app, the daemon got the repo's sites.txt as its argument
        if let data = FileManager.default.contents(atPath: Paths.daemonPlist),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let arguments = plist["ProgramArguments"] as? [String], arguments.count > 1 {
            candidates.append(arguments[1])
        }
        return candidates
            .filter { $0 != Paths.sitesFile.path && FileManager.default.fileExists(atPath: $0) }
            .map { URL(fileURLWithPath: $0) }
            .first
    }
}

struct SitesWindow: View {
    @EnvironmentObject private var status: FocusStatus
    @State private var text = ""
    @State private var saved = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("One domain per line, without www. Lines starting with # are ignored.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body.monospaced())
                .border(Color(nsColor: .separatorColor))
            HStack {
                if let error = status.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if status.breakEnd != nil {
                    Text("Changes apply when the break ends.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Revert") { text = saved }
                    .disabled(text == saved)
                Button("Save") {
                    status.saveSites(text)
                    saved = text
                }
                .keyboardShortcut("s")
                .disabled(text == saved)
            }
        }
        .padding()
        .frame(minWidth: 380, minHeight: 320)
        .onAppear {
            try? SitesFile.createIfMissing()
            text = SitesFile.read()
            saved = text
        }
    }
}
