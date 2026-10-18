import AppKit
import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var status: FocusStatus
    @Environment(\.openWindow) private var openWindow
    @State private var customMinutes = 20
    @State private var openAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            if !status.installed {
                installSection
            } else if let end = status.breakEnd {
                breakSection(until: end)
            } else {
                focusedSection
            }
            if let error = status.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 280)
        .disabled(status.busy)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !status.installed {
                Label("Not installed", systemImage: "exclamationmark.triangle")
                    .font(.headline)
            } else if let end = status.breakEnd {
                Label("On a break · \(formatCountdown(until: end)) left", systemImage: "lock.open")
                    .font(.headline)
                    .monospacedDigit()
            } else {
                Label("Sites are blocked", systemImage: "lock.fill")
                    .font(.headline)
            }
            Text("Today on breaks: \(formatDuration(status.todayTotal))")
                .foregroundStyle(.secondary)
        }
    }

    private var installSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Install blocks the sites in your list now and at every boot. macOS will ask for your password.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Button("Install") { status.install() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var focusedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Take a break")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                ForEach([5, 10, 15], id: \.self) { minutes in
                    Button("\(minutes) min") { status.startBreak(minutes: minutes) }
                }
            }
            HStack {
                Stepper("\(customMinutes) min", value: $customMinutes, in: 1...120, step: 5)
                    .monospacedDigit()
                Button("Start") { status.startBreak(minutes: customMinutes) }
            }
        }
    }

    private func breakSection(until end: Date) -> some View {
        Button("End break now") { status.endBreak() }
            .buttonStyle(.borderedProminent)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button("Edit sites…") {
                openWindow(id: "sites")
                NSApp.activate(ignoringOtherApps: true)
            }
            Toggle("Open at login", isOn: $openAtLogin)
                .onChange(of: openAtLogin) { enabled in
                    do {
                        try LoginItem.setEnabled(enabled)
                    } catch {
                        status.error = error.localizedDescription
                        openAtLogin = LoginItem.isEnabled
                    }
                }
            if status.installed {
                Button("Uninstall…") { status.uninstall() }
            }
            Button("Quit Focus") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
    }
}

/// "4:07"
func formatCountdown(until end: Date) -> String {
    let seconds = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
}

/// "0 min", "17 min", "1 h 5 min"
func formatDuration(_ interval: TimeInterval) -> String {
    let minutes = Int(interval / 60)
    return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h \(minutes % 60) min"
}
