import FocusCore
import SwiftUI

enum Theme {
    /// The ring's gold, for the blocked state. Deeper than the icon's gold,
    /// so white text on it stays readable.
    static let focus = Color(red: 0.71, green: 0.52, blue: 0.17)
    /// Warm orange for breaks, the Eye's fire
    static let onBreak = Color(red: 0.97, green: 0.53, blue: 0.20)
}

extension View {
    /// A softly tinted rounded panel
    func card(tint: Color) -> some View {
        padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.20), tint.opacity(0.06)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
            )
    }
}

/// A filled, full-width call to action
struct ProminentButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, tint: tint)
    }

    private struct Styled: View {
        let configuration: Configuration
        let tint: Color
        @State private var hovering = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.gradient)
                        .brightness(hovering && isEnabled ? 0.06 : 0)
                )
                .shadow(color: tint.opacity(isEnabled ? 0.35 : 0), radius: 6, y: 2)
                .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }
    }
}

/// A tinted tile, for the break lengths
struct ChipButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        Styled(configuration: configuration, tint: tint)
    }

    private struct Styled: View {
        let configuration: Configuration
        let tint: Color
        @State private var hovering = false

        var body: some View {
            configuration.label
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(configuration.isPressed ? 0.32 : hovering ? 0.22 : 0.13))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(tint.opacity(hovering ? 0.45 : 0.2), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
        }
    }
}

/// A row that highlights on hover, like a menu item
struct MenuRow: View {
    let title: String
    let symbol: String
    var detail: String?
    var checked = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(title)
                Spacer()
                if let detail {
                    Text(detail)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if checked {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.focus)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.08 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// The ring mark in a filled circle, for the current state
struct StateBadge: View {
    let tint: Color

    var body: some View {
        RingMark(size: 22)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(tint.gradient))
            .shadow(color: tint.opacity(0.4), radius: 6, y: 3)
    }
}

/// How much of the break is left, as a ring that empties
struct BreakRing: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            // The ring is on: the Eye looks out of it
            PupilShape()
                .fill(tint)
                .frame(width: 13, height: 30)
        }
        .frame(width: 58, height: 58)
    }
}

/// Today from midnight to midnight, with each break as a segment
struct DayTimeline: View {
    let breaks: [BreakLog.Interval]
    let tint: Color

    var body: some View {
        let dayStart = Calendar.current.startOfDay(for: Date())
        VStack(spacing: 5) {
            GeometryReader { geometry in
                let x: (Date) -> CGFloat = { geometry.size.width * $0.timeIntervalSince(dayStart) / 86_400 }
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    ForEach(Array(breaks.enumerated()), id: \.offset) { _, interval in
                        Capsule()
                            .fill(tint)
                            .frame(width: max(4, x(interval.end) - x(interval.start)))
                            .offset(x: x(interval.start))
                    }
                    Capsule()
                        .fill(Color.primary.opacity(0.55))
                        .frame(width: 2, height: 14)
                        .offset(x: x(Date()) - 1)
                }
            }
            .frame(height: 8)
            HStack {
                ForEach(Array(["00", "06", "12", "18", "24"].enumerated()), id: \.offset) { index, hour in
                    if index > 0 { Spacer() }
                    Text(hour)
                }
            }
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .foregroundStyle(.tertiary)
        }
    }
}

/// "TODAY ON BREAKS"
struct SectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.red.opacity(0.12)))
    }
}
