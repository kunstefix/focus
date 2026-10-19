import Foundation

/// The sites file as src/focus.sh reads it: one bare domain per line, with
/// comments and blank lines skipped. Edits keep every other line as it was.
public struct SitesList: Equatable {
    public private(set) var lines: [String]

    public init(text: String) {
        lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if lines.last == "" {
            lines.removeLast()
        }
    }

    public var text: String {
        lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }

    /// The domains focus.sh blocks, in file order
    public var domains: [String] {
        lines.compactMap(Self.domain(inLine:))
    }

    /// Adds a domain typed or pasted by the user. Returns false if it isn't a
    /// domain or is already in the list.
    @discardableResult
    public mutating func add(_ input: String) -> Bool {
        guard let domain = Self.normalize(input), !domains.contains(domain) else { return false }
        lines.append(domain)
        return true
    }

    public mutating func remove(_ domain: String) {
        lines.removeAll { Self.domain(inLine: $0) == domain }
    }

    /// "https://www.Reddit.com/r/foo" → "reddit.com"; nil if it isn't a domain
    public static func normalize(_ input: String) -> String? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let scheme = text.range(of: "://") {
            text = String(text[scheme.upperBound...])
        }
        text = String(text.prefix { !"/?#:".contains($0) })
        if text.hasPrefix("www.") {
            text.removeFirst(4)
        }
        let isDomain = text.range(of: #"^[a-z0-9-]+(\.[a-z0-9-]+)+$"#, options: .regularExpression) != nil
        return isDomain ? text : nil
    }

    /// Mirrors the checks in focus.sh
    private static func domain(inLine line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\r")))
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#"),
              trimmed.range(of: #"^[A-Za-z0-9.-]+$"#, options: .regularExpression) != nil
        else { return nil }
        return trimmed
    }
}
