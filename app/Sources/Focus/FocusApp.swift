import AppKit
import SwiftUI

@main
struct FocusApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(appDelegate.status)
        } label: {
            MenuBarLabel()
                .environmentObject(appDelegate.status)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject private var status: FocusStatus

    var body: some View {
        if let end = status.breakEnd {
            Text("\(Image(systemName: "lock.open")) \(formatCountdown(until: end))")
                .monospacedDigit()
        } else {
            Image(systemName: "lock.fill")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// LoginItem passes this, so starting at login doesn't pop up a window
    nonisolated static let loginArgument = "--login"
    private static let showNotification = Notification.Name("io.github.kunstefix.focus.app.show")

    let status = FocusStatus()

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if let index = CommandLine.arguments.firstIndex(of: "--render-previews"),
           CommandLine.arguments.indices.contains(index + 1) {
            PreviewRenderer.render(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
            exit(0)
        }
        #endif

        // Info.plist sets LSUIElement in the bundle; this covers `swift run`
        NSApp.setActivationPolicy(.accessory)

        // Another copy (e.g. one in Applications and one on the DMG) is
        // already running: have it show its window instead of adding a second icon
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if !others.isEmpty {
            DistributedNotificationCenter.default().postNotificationName(Self.showNotification, object: nil,
                                                                         deliverImmediately: true)
            NSApp.terminate(nil)
            return
        }
        DistributedNotificationCenter.default().addObserver(forName: Self.showNotification, object: nil,
                                                            queue: .main) { [weak self] _ in
            Task { @MainActor in self?.showStatusWindow() }
        }

        // Keep the login item pointing at this copy of the app if it moved
        if LoginItem.isEnabled {
            try? LoginItem.setEnabled(true)
        }

        // The menu bar icon can be hidden behind the notch when the bar is
        // full, so opening the app by hand always shows something
        if !CommandLine.arguments.contains(Self.loginArgument) {
            showStatusWindow()
        }
    }

    /// Opening the app again while it runs
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showStatusWindow()
        return false
    }

    private func showStatusWindow() {
        Windows.show("status", title: "Focus", MenuView().environmentObject(status))
    }
}

/// AppKit windows hosting SwiftUI views, so they can be opened from the app
/// delegate as well as from the menu
@MainActor
enum Windows {
    private static var windows: [String: NSWindow] = [:]

    static func show<Content: View>(_ id: String, title: String, _ content: Content) {
        let window = windows[id] ?? {
            let window = NSWindow(contentViewController: NSHostingController(rootView: content))
            window.title = title
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.center()
            windows[id] = window
            return window
        }()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
