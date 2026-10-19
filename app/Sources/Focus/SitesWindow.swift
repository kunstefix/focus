import FocusCore
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

/// Edits the sites file a domain at a time. Comments in the file are kept.
/// Every change is saved and applied right away.
struct SitesWindow: View {
    @EnvironmentObject private var status: FocusStatus
    @State private var list: SitesList
    @State private var newSite = ""
    @State private var hint: String?
    @FocusState private var fieldFocused: Bool

    init(list: SitesList? = nil) {
        _list = State(initialValue: list ?? {
            try? SitesFile.createIfMissing()
            return SitesList(text: SitesFile.read())
        }())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Blocked sites")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(status.breakEnd == nil
                     ? "Each site is blocked with and without www. Changes apply right away."
                     : "You're on a break. Changes apply when it ends.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            addField
            if list.domains.isEmpty {
                emptyState
            } else {
                siteList
            }
            if let error = status.error {
                ErrorBanner(message: error)
            }
        }
        .padding(20)
        .frame(width: 420, height: 520)
    }

    private var addField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)
                    TextField("Add a site, like youtube.com", text: $newSite)
                        .textFieldStyle(.plain)
                        .focused($fieldFocused)
                        .onSubmit(add)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.05)))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(fieldFocused ? Theme.focus.opacity(0.7) : Color.primary.opacity(0.1), lineWidth: 1)
                )
                Button("Add", action: add)
                    .buttonStyle(ProminentButtonStyle(tint: Theme.focus))
                    .frame(width: 76)
                    .disabled(SitesList.normalize(newSite) == nil)
            }
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
        .onChange(of: newSite) { _ in hint = nil }
    }

    private var siteList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(list.domains.enumerated()), id: \.element) { index, domain in
                        if index > 0 {
                            Divider().padding(.leading, 54)
                        }
                        SiteRow(domain: domain) { remove(domain) }
                    }
                }
                .padding(.vertical, 4)
            }
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.035)))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            Text(list.domains.count == 1 ? "1 site" : "\(list.domains.count) sites")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.focus.opacity(0.7))
            Text("No sites blocked yet")
                .font(.system(.headline, design: .rounded))
            Text("Add the sites you reach for out of habit.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.035)))
    }

    private func add() {
        guard let domain = SitesList.normalize(newSite) else { return }
        guard list.add(domain) else {
            hint = "\(domain) is already blocked."
            return
        }
        newSite = ""
        status.saveSites(list.text)
    }

    private func remove(_ domain: String) {
        list.remove(domain)
        status.saveSites(list.text)
    }
}

private struct SiteRow: View {
    let domain: String
    let onRemove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            Text(domain.prefix(1).uppercased())
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(domain)
                    .font(.body.weight(.medium))
                Text("www.\(domain)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.red.opacity(hovering ? 0.9 : 0.35))
            .help("Unblock \(domain)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(hovering ? 0.04 : 0))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    /// A stable colour per domain (String.hashValue changes between launches)
    private var color: Color {
        let sum = domain.unicodeScalars.reduce(0) { $0 + Int($1.value) * 31 }
        return Color(hue: Double(sum % 360) / 360, saturation: 0.5, brightness: 0.82)
    }
}
