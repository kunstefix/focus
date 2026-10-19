import AppKit
import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var status: FocusStatus
    @State private var openAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            hero
            if status.installed {
                today
                if status.breakEnd == nil {
                    breakPicker
                }
            }
            if let error = status.error {
                ErrorBanner(message: error)
            }
            VStack(spacing: 8) {
                Divider()
                menuRows
            }
        }
        .padding(16)
        .frame(width: 300)
        .disabled(status.busy)
        .animation(.easeInOut(duration: 0.25), value: status.breakEnd == nil)
        .animation(.easeInOut(duration: 0.25), value: status.installed)
    }

    // MARK: State

    @ViewBuilder
    private var hero: some View {
        if !status.installed {
            installCard
        } else if let start = status.breakStart, let end = status.breakEnd {
            breakCard(start: start, end: end)
        } else {
            focusedCard
        }
    }

    private var focusedCard: some View {
        HStack(spacing: 12) {
            StateBadge(symbol: "lock.fill", tint: Theme.focus)
            VStack(alignment: .leading, spacing: 2) {
                Text("Focused")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Text(status.siteCount == 1 ? "1 site blocked" : "\(status.siteCount) sites blocked")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            spinner
        }
        .card(tint: Theme.focus)
    }

    private func breakCard(start: Date, end: Date) -> some View {
        let total = max(1, end.timeIntervalSince(start))
        let progress = min(1, max(0, end.timeIntervalSinceNow / total))
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                BreakRing(progress: progress, tint: Theme.onBreak)
                VStack(alignment: .leading, spacing: 0) {
                    Text("On a break")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.onBreak)
                    Text(formatCountdown(until: end))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("Blocking again at \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                spinner
            }
            Button("End break now") { status.endBreak() }
                .buttonStyle(ProminentButtonStyle(tint: Theme.onBreak))
        }
        .card(tint: Theme.onBreak)
    }

    private var installCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                StateBadge(symbol: "lock.shield.fill", tint: Theme.focus)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up Focus")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    Text("Block your sites now and at every boot.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: 6) {
                Button("Install") { status.install() }
                    .buttonStyle(ProminentButtonStyle(tint: Theme.focus))
                Text("macOS will ask for your password.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card(tint: Theme.focus)
    }

    @ViewBuilder
    private var spinner: some View {
        if status.busy {
            ProgressView()
                .controlSize(.small)
        }
    }

    // MARK: Today

    private var today: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel("Today on breaks")
                Spacer()
                Text(status.todayBreaks.count == 1 ? "1 break" : "\(status.todayBreaks.count) breaks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            durationText(status.todayTotal)
            DayTimeline(breaks: status.todayBreaks, tint: Theme.onBreak)
        }
        .padding(.horizontal, 4)
    }

    /// "1 h 5 min" with the numbers large and the units small
    private func durationText(_ interval: TimeInterval) -> Text {
        let minutes = Int(interval / 60)
        let number = { (value: Int) in
            Text("\(value)").font(.system(size: 28, weight: .semibold, design: .rounded))
        }
        let unit = { (value: String) in
            Text(value).font(.system(.callout, design: .rounded).weight(.medium)).foregroundColor(.secondary)
        }
        guard minutes >= 60 else { return number(minutes) + unit(" min") }
        return number(minutes / 60) + unit(" h  ") + number(minutes % 60) + unit(" min")
    }

    // MARK: Break

    private var breakPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Take a break")
            HStack(spacing: 8) {
                ForEach([5, 10, 15, 30], id: \.self) { minutes in
                    Button { status.startBreak(minutes: minutes) } label: {
                        VStack(spacing: -2) {
                            Text("\(minutes)")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                            Text("min")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                    }
                    .buttonStyle(ChipButtonStyle(tint: Theme.onBreak))
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: Menu

    private var menuRows: some View {
        VStack(spacing: 1) {
            MenuRow(title: "Blocked sites…", symbol: "list.bullet", detail: "\(status.siteCount)") {
                Windows.show("sites", title: "Blocked Sites", SitesWindow().environmentObject(status))
            }
            MenuRow(title: "Open at login", symbol: "power", checked: openAtLogin) {
                do {
                    try LoginItem.setEnabled(!openAtLogin)
                } catch {
                    status.error = error.localizedDescription
                }
                openAtLogin = LoginItem.isEnabled
            }
            if status.installed {
                MenuRow(title: "Uninstall…", symbol: "trash") { status.uninstall() }
            }
            MenuRow(title: "Quit Focus", symbol: "xmark.circle", detail: "⌘Q") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

/// "4:07"
func formatCountdown(until end: Date) -> String {
    let seconds = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
}
