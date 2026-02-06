import AppKit
import Foundation

enum IconKind {
    case menubar
    case app
}

private extension NSColor {
    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
        NSColor(calibratedRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}

private func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

private func withNormalizedCanvas(_ context: CGContext, size: CGFloat, _ draw: () -> Void) {
    context.saveGState()
    context.translateBy(x: 0, y: 0)
    context.scaleBy(x: size, y: size)
    draw()
    context.restoreGState()
}

private func stroke(
    _ path: NSBezierPath,
    color: NSColor,
    width: CGFloat,
    cap: NSBezierPath.LineCapStyle = .round,
    join: NSBezierPath.LineJoinStyle = .round
) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = cap
    path.lineJoinStyle = join
    path.stroke()
}

private func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

private func drawMenuBarGlyph(in context: CGContext, size: Int) {
    let canvas = CGFloat(size)
    withNormalizedCanvas(context, size: canvas) {
        let strokeColor = NSColor.black
        let lineWidth: CGFloat = 0.10

        let head = NSBezierPath(ovalIn: CGRect(x: 0.20, y: 0.22, width: 0.60, height: 0.54))
        let leftEar = NSBezierPath(ovalIn: CGRect(x: 0.05, y: 0.47, width: 0.28, height: 0.28))
        let rightEar = NSBezierPath(ovalIn: CGRect(x: 0.67, y: 0.47, width: 0.28, height: 0.28))

        stroke(head, color: strokeColor, width: lineWidth)
        stroke(leftEar, color: strokeColor, width: lineWidth)
        stroke(rightEar, color: strokeColor, width: lineWidth)

        let nose = NSBezierPath(roundedRect: CGRect(x: 0.44, y: 0.34, width: 0.12, height: 0.17), xRadius: 0.06, yRadius: 0.06)
        fill(nose, color: strokeColor)

        let stem = NSBezierPath()
        stem.move(to: CGPoint(x: 0.50, y: 0.76))
        stem.line(to: CGPoint(x: 0.50, y: 0.86))
        stroke(stem, color: strokeColor, width: lineWidth * 0.65)

        let leaf = NSBezierPath(ovalIn: CGRect(x: 0.46, y: 0.84, width: 0.08, height: 0.11))
        stroke(leaf, color: strokeColor, width: lineWidth * 0.60)
    }
}

private func drawAppIcon(in context: CGContext, size: Int) {
    let canvas = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: canvas, height: canvas)
    let radius = canvas * 0.225

    context.saveGState()
    let clipPath = roundedRectPath(rect, radius: radius)
    clipPath.addClip()

    let bgGradient = NSGradient(colors: [
        .rgb(42, 64, 255),
        .rgb(34, 170, 255),
        .rgb(55, 226, 211)
    ])!
    bgGradient.draw(in: rect, angle: 55)

    let glowRect = CGRect(x: canvas * 0.10, y: canvas * 0.55, width: canvas * 0.80, height: canvas * 0.45)
    let glowGradient = NSGradient(starting: NSColor(white: 1, alpha: 0.40), ending: NSColor(white: 1, alpha: 0.0))!
    glowGradient.draw(in: glowRect, relativeCenterPosition: .zero)

    context.restoreGState()

    withNormalizedCanvas(context, size: canvas) {
        let shell = NSBezierPath(roundedRect: CGRect(x: 0.11, y: 0.11, width: 0.78, height: 0.78), xRadius: 0.24, yRadius: 0.24)
        fill(shell, color: NSColor(white: 1, alpha: 0.20))
        stroke(shell, color: NSColor(white: 1, alpha: 0.35), width: 0.016)

        let leftEar = NSBezierPath(ovalIn: CGRect(x: 0.18, y: 0.48, width: 0.22, height: 0.22))
        let rightEar = NSBezierPath(ovalIn: CGRect(x: 0.60, y: 0.48, width: 0.22, height: 0.22))
        let face = NSBezierPath(ovalIn: CGRect(x: 0.24, y: 0.23, width: 0.52, height: 0.45))

        fill(leftEar, color: NSColor(white: 1, alpha: 0.70))
        fill(rightEar, color: NSColor(white: 1, alpha: 0.70))
        fill(face, color: NSColor(white: 1, alpha: 0.82))

        stroke(leftEar, color: NSColor(white: 1, alpha: 0.30), width: 0.012)
        stroke(rightEar, color: NSColor(white: 1, alpha: 0.30), width: 0.012)
        stroke(face, color: NSColor(white: 1, alpha: 0.35), width: 0.012)

        let leftEye = NSBezierPath(roundedRect: CGRect(x: 0.37, y: 0.43, width: 0.06, height: 0.09), xRadius: 0.02, yRadius: 0.02)
        let rightEye = NSBezierPath(roundedRect: CGRect(x: 0.57, y: 0.43, width: 0.06, height: 0.09), xRadius: 0.02, yRadius: 0.02)
        fill(leftEye, color: .rgb(15, 40, 95, 0.45))
        fill(rightEye, color: .rgb(15, 40, 95, 0.45))

        let nose = NSBezierPath(roundedRect: CGRect(x: 0.45, y: 0.33, width: 0.10, height: 0.14), xRadius: 0.05, yRadius: 0.05)
        fill(nose, color: .rgb(9, 29, 84, 0.88))

        let stem = NSBezierPath()
        stem.move(to: CGPoint(x: 0.50, y: 0.70))
        stem.line(to: CGPoint(x: 0.50, y: 0.80))
        stroke(stem, color: NSColor(white: 1, alpha: 0.78), width: 0.014)

        let leafLeft = NSBezierPath(ovalIn: CGRect(x: 0.44, y: 0.78, width: 0.08, height: 0.12))
        let leafRight = NSBezierPath(ovalIn: CGRect(x: 0.50, y: 0.78, width: 0.08, height: 0.12))
        fill(leafLeft, color: .rgb(192, 255, 230, 0.85))
        fill(leafRight, color: .rgb(166, 255, 214, 0.78))
        stroke(leafLeft, color: NSColor(white: 1, alpha: 0.45), width: 0.010)
        stroke(leafRight, color: NSColor(white: 1, alpha: 0.38), width: 0.010)

        let gloss = NSBezierPath()
        gloss.move(to: CGPoint(x: 0.13, y: 0.85))
        gloss.curve(to: CGPoint(x: 0.87, y: 0.73), controlPoint1: CGPoint(x: 0.35, y: 0.95), controlPoint2: CGPoint(x: 0.72, y: 0.89))
        gloss.curve(to: CGPoint(x: 0.87, y: 0.66), controlPoint1: CGPoint(x: 0.89, y: 0.71), controlPoint2: CGPoint(x: 0.89, y: 0.67))
        gloss.curve(to: CGPoint(x: 0.13, y: 0.76), controlPoint1: CGPoint(x: 0.72, y: 0.79), controlPoint2: CGPoint(x: 0.34, y: 0.86))
        gloss.close()
        fill(gloss, color: NSColor(white: 1, alpha: 0.20))

        let outerBorder = NSBezierPath(roundedRect: CGRect(x: 0.008, y: 0.008, width: 0.984, height: 0.984), xRadius: 0.225, yRadius: 0.225)
        stroke(outerBorder, color: NSColor(white: 1, alpha: 0.23), width: 0.008)
    }
}

private func drawIcon(in context: CGContext, size: Int, kind: IconKind) {
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    switch kind {
    case .menubar:
        NSColor.clear.setFill()
        CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)).fill()
        drawMenuBarGlyph(in: context, size: size)
    case .app:
        drawAppIcon(in: context, size: size)
    }
}

private func renderPNG(size: Int, kind: IconKind, to url: URL, previewBackground: NSColor? = nil) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap rep"])
    }

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "IconGen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    if let previewBackground {
        previewBackground.setFill()
        CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)).fill()
    }
    drawIcon(in: ctx.cgContext, size: size, kind: kind)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }

    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

struct GenerateIcons {
    static func run() throws {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)

        let menubar1x = cwd.appendingPathComponent("Sources/LumeBar/Resources/Assets.xcassets/MenubarIcon.imageset/menubar-1x.png")
        let menubar2x = cwd.appendingPathComponent("Sources/LumeBar/Resources/Assets.xcassets/MenubarIcon.imageset/menubar-2x.png")

        let appIconDir = cwd.appendingPathComponent("Sources/LumeBar/Resources/Assets.xcassets/AppIcon.appiconset")
        let appIcon16 = appIconDir.appendingPathComponent("appicon-16.png")
        let appIcon32 = appIconDir.appendingPathComponent("appicon-32.png")
        let appIcon64 = appIconDir.appendingPathComponent("appicon-64.png")
        let appIcon128 = appIconDir.appendingPathComponent("appicon-128.png")
        let appIcon256 = appIconDir.appendingPathComponent("appicon-256.png")
        let appIcon512 = appIconDir.appendingPathComponent("appicon-512.png")
        let appIcon1024 = appIconDir.appendingPathComponent("appicon-1024.png")

        try renderPNG(size: 18, kind: .menubar, to: menubar1x)
        try renderPNG(size: 36, kind: .menubar, to: menubar2x)

        try renderPNG(size: 16, kind: .app, to: appIcon16)
        try renderPNG(size: 32, kind: .app, to: appIcon32)
        try renderPNG(size: 64, kind: .app, to: appIcon64)
        try renderPNG(size: 128, kind: .app, to: appIcon128)
        try renderPNG(size: 256, kind: .app, to: appIcon256)
        try renderPNG(size: 512, kind: .app, to: appIcon512)
        try renderPNG(size: 1024, kind: .app, to: appIcon1024)

        let appPreview = cwd.appendingPathComponent("output/icon-preview-app-512.png")
        try renderPNG(size: 512, kind: .app, to: appPreview)

        let menubarLight = cwd.appendingPathComponent("output/icon-preview-menubar-light-128.png")
        let menubarDark = cwd.appendingPathComponent("output/icon-preview-menubar-dark-128.png")
        try renderPNG(size: 128, kind: .menubar, to: menubarLight, previewBackground: NSColor(white: 0.95, alpha: 1))
        try renderPNG(size: 128, kind: .menubar, to: menubarDark, previewBackground: NSColor(white: 0.10, alpha: 1))

        print("Generated icons:")
        print("- \(menubar1x.path)")
        print("- \(menubar2x.path)")
        print("- \(appIcon1024.path) (and other sizes)")
        print("- \(appPreview.path)")
        print("- \(menubarLight.path)")
        print("- \(menubarDark.path)")
    }
}

try GenerateIcons.run()
