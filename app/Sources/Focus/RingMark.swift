import AppKit
import SwiftUI

/// The ring from the landing page logo: a band whose outer edge fills the
/// frame. Use with `.stroke(lineWidth:)` sized by `RingMark.band`.
struct RingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let inset = side * RingMark.band / 2
        let square = CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        return Path(ellipseIn: square.insetBy(dx: inset, dy: inset))
    }
}

/// The Eye's vertical slit pupil
struct PupilShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let height = rect.height / 2
        let bulge = rect.width / 2
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - height))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + height),
                          control: CGPoint(x: center.x + bulge, y: center.y))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - height),
                          control: CGPoint(x: center.x - bulge, y: center.y))
        return path
    }
}

/// The app's mark. While focused it's a plain ring; on a break the ring is
/// on, and the Eye looks out of it.
struct RingMark: View {
    /// Band width as a share of the ring's diameter
    static let band: CGFloat = 0.16

    var eye = false
    var size: CGFloat

    var body: some View {
        ZStack {
            RingShape()
                .stroke(lineWidth: size * Self.band)
            if eye {
                PupilShape()
                    .frame(width: size * 0.22, height: size * 0.52)
            }
        }
        .frame(width: size, height: size)
    }
}

/// The menu bar label as a template image. MenuBarExtra ignores frames and
/// font features in its label, so drawing it is the way to get the custom
/// mark and a countdown of fixed width, which keeps the icons beside it
/// from shifting as the digits change.
@MainActor
func menuBarImage(countdown: String?) -> NSImage {
    let content = HStack(spacing: 4) {
        RingMark(eye: countdown != nil, size: 15)
        if let countdown {
            ZStack(alignment: .leading) {
                // Sized for the widest countdown of up to 99 minutes
                Text("00:00").hidden()
                Text(countdown)
            }
        }
    }
    .font(Font(NSFont.menuBarFont(ofSize: 0)))
    .monospacedDigit()
    .foregroundStyle(.black)
    .padding(.vertical, 1)

    let renderer = ImageRenderer(content: content)
    renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
    let image = renderer.nsImage ?? NSImage()
    // A template image follows the menu bar's light or dark appearance
    image.isTemplate = true
    return image
}
