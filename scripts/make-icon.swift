// Draws the app icon: a glowing gold ring on a dark ash tile, like the landing page.
// Usage: swift make-icon.swift <out.png>   (1024×1024)
import AppKit

let size: CGFloat = 1024
// An explicit bitmap, so the output is 1024 px whatever the screen's scale
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

func color(_ hex: Int) -> NSColor {
    NSColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

// macOS icons leave a margin around the rounded square
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(starting: color(0x3A2B24), ending: color(0x1E1714))!.draw(in: tilePath, angle: -90)

// The ring: a band of 92 px, its outer edge 520 px across
let band: CGFloat = 92
let outer: CGFloat = 520
let ringRect = NSRect(x: (size - outer) / 2, y: (size - outer) / 2, width: outer, height: outer)
    .insetBy(dx: band / 2, dy: band / 2)
let ring = NSBezierPath(ovalIn: ringRect)
ring.lineWidth = band

NSGraphicsContext.saveGraphicsState()
tilePath.addClip()
// Ember glow behind the ring
let glow = NSShadow()
glow.shadowColor = color(0xF2601B).withAlphaComponent(0.75)
glow.shadowBlurRadius = 90
glow.set()
color(0xD9AE52).setStroke()
ring.stroke()
NSGraphicsContext.restoreGraphicsState()

// Gold gradient along the band, light at the top left
NSGraphicsContext.saveGraphicsState()
let bandOutline = NSBezierPath(cgPath: ring.cgPath.copy(strokingWithWidth: band, lineCap: .butt,
                                                        lineJoin: .miter, miterLimit: 10))
bandOutline.addClip()
NSGradient(starting: color(0xF4D58A), ending: color(0xB8862E))!.draw(in: ringRect.insetBy(dx: -band, dy: -band),
                                                                    angle: -45)
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.current?.flushGraphics()
try! bitmap.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
