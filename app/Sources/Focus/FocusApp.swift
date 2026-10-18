import AppKit
import SwiftUI

@main
struct FocusApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var status = FocusStatus()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(status)
        } label: {
            if let end = status.breakEnd {
                Text("\(Image(systemName: "lock.open")) \(formatCountdown(until: end))")
                    .monospacedDigit()
            } else {
                Image(systemName: "lock.fill")
            }
        }
        .menuBarExtraStyle(.window)

        Window("Blocked Sites", id: "sites") {
            SitesWindow()
                .environmentObject(status)
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Info.plist sets LSUIElement in the bundle; this covers `swift run`
        NSApp.setActivationPolicy(.accessory)
        // Keep the login item pointing at this copy of the app if it moved
        if LoginItem.isEnabled {
            try? LoginItem.setEnabled(true)
        }
    }
}
