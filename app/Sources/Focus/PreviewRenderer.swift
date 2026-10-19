#if DEBUG
import FocusCore
import SwiftUI

/// `Focus --render-previews <dir>` writes PNGs of the views in each state and
/// appearance, to check the design without installing anything.
/// AppKit-backed controls (text fields, scroll views) render as placeholders.
@MainActor
enum PreviewRenderer {
    static func render(to directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let breaks: [(hour: Double, minutes: Double)] = [(9.2, 5), (11.5, 10), (14.1, 15)]
        let states: [(String, FocusStatus)] = [
            ("install", .preview(installed: false)),
            ("focused", .preview(todayBreaks: breaks)),
            ("break", .preview(breakMinutes: (10, 6.4), todayBreaks: breaks + [(15.9, 3.6)])),
            ("error", .preview(todayBreaks: breaks, error: "sudo: a password is required")),
        ]
        let sites = SitesList(text: "# social\nreddit.com\nx.com\ninstagram.com\nnews.ycombinator.com\nyoutube.com\n")
        for scheme in [ColorScheme.light, .dark] {
            for (name, status) in states {
                write(MenuView().environmentObject(status), scheme: scheme, to: directory, name: "menu-\(name)")
            }
            write(SitesWindow(list: sites).environmentObject(FocusStatus.preview()), scheme: scheme,
                  to: directory, name: "sites")
        }
    }

    private static func write<Content: View>(_ view: Content, scheme: ColorScheme, to directory: URL, name: String) {
        let background = scheme == .dark ? Color(white: 0.16) : Color(white: 0.96)
        let renderer = ImageRenderer(content: view.background(background).environment(\.colorScheme, scheme))
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: directory.appendingPathComponent("\(name)-\(scheme == .dark ? "dark" : "light").png"))
    }
}
#endif
