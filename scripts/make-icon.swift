// Draws the app icon: a white lock on a rounded indigo square.
// Usage: swift make-icon.swift <out.png>   (1024×1024)
import AppKit

let size: CGFloat = 1024
// An explicit bitmap, so the output is 1024 px whatever the screen's scale
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

// macOS icons leave a margin around the rounded square
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let gradient = NSGradient(starting: NSColor(red: 0.36, green: 0.33, blue: 0.95, alpha: 1),
                          ending: NSColor(red: 0.18, green: 0.15, blue: 0.55, alpha: 1))!
gradient.draw(in: NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185), angle: -90)

let config = NSImage.SymbolConfiguration(pointSize: 440, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
let lock = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(config)!
lock.draw(in: NSRect(x: (size - lock.size.width) / 2, y: (size - lock.size.height) / 2,
                     width: lock.size.width, height: lock.size.height))

NSGraphicsContext.current?.flushGraphics()
try! bitmap.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
