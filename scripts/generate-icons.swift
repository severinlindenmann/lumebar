import AppKit
import Foundation

struct IconStyle {
    let background: NSColor?
    let stroke: NSColor
    let fill: NSColor
    let leafStroke: NSColor
    let lineWidthFraction: CGFloat
}

enum IconKind {
    case menubar
    case app
}

private func drawIcon(in context: CGContext, size: Int, kind: IconKind) {
    context.setShouldAntialias(true)
    context.setAllowsAntialiasing(true)
    context.interpolationQuality = .high

    let rect = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))

    let style: IconStyle = {
        switch kind {
        case .menubar:
            return IconStyle(
                background: nil,
                stroke: .black,
                fill: .black,
                leafStroke: .black,
                lineWidthFraction: 0.060
            )
        case .app:
            return IconStyle(
                background: NSColor(white: 0.97, alpha: 1),
                stroke: .black,
                fill: .black,
                leafStroke: .black,
                lineWidthFraction: 0.055
            )
        }
    }()

    if let background = style.background {
        background.setFill()

        // Rounded app icon background.
        let cornerRadius = rect.width * 0.22
        NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
    } else {
        NSColor.clear.setFill()
        rect.fill()
    }

    // After we scale the context to normalized 0..1 coordinates, line widths must be in that same space.
    let lw = style.lineWidthFraction

    func strokePath(_ path: NSBezierPath, color: NSColor = style.stroke, width: CGFloat = lw) {
        color.setStroke()
        path.lineWidth = width
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    func fillPath(_ path: NSBezierPath, color: NSColor = style.fill) {
        color.setFill()
        path.fill()
    }

    // Work in normalized coordinates (0..1), then scale to pixels.
    context.saveGState()
    context.translateBy(x: rect.minX, y: rect.minY)
    context.scaleBy(x: rect.width, y: rect.height)

    // Koala head outline (inspired by original Lume icon).
    let head = NSBezierPath(ovalIn: CGRect(x: 0.14, y: 0.18, width: 0.72, height: 0.62))
    let leftEar = NSBezierPath(ovalIn: CGRect(x: 0.02, y: 0.50, width: 0.30, height: 0.30))
    let rightEar = NSBezierPath(ovalIn: CGRect(x: 0.68, y: 0.50, width: 0.30, height: 0.30))

    strokePath(head)
    strokePath(leftEar)
    strokePath(rightEar)

    // Eyes (skip for menubar for clarity at 18px).
    if kind == .app {
        fillPath(NSBezierPath(roundedRect: CGRect(x: 0.30, y: 0.41, width: 0.10, height: 0.16), xRadius: 0.035, yRadius: 0.035))
        fillPath(NSBezierPath(roundedRect: CGRect(x: 0.60, y: 0.41, width: 0.10, height: 0.16), xRadius: 0.035, yRadius: 0.035))
    }

    // Nose (rounded triangle / teardrop).
    let nose = NSBezierPath()
    nose.move(to: CGPoint(x: 0.50, y: 0.28))
    nose.curve(to: CGPoint(x: 0.40, y: 0.36), controlPoint1: CGPoint(x: 0.46, y: 0.28), controlPoint2: CGPoint(x: 0.41, y: 0.31))
    nose.curve(to: CGPoint(x: 0.45, y: 0.58), controlPoint1: CGPoint(x: 0.35, y: 0.44), controlPoint2: CGPoint(x: 0.38, y: 0.56))
    nose.curve(to: CGPoint(x: 0.55, y: 0.58), controlPoint1: CGPoint(x: 0.47, y: 0.60), controlPoint2: CGPoint(x: 0.53, y: 0.60))
    nose.curve(to: CGPoint(x: 0.60, y: 0.36), controlPoint1: CGPoint(x: 0.62, y: 0.56), controlPoint2: CGPoint(x: 0.65, y: 0.44))
    nose.curve(to: CGPoint(x: 0.50, y: 0.28), controlPoint1: CGPoint(x: 0.59, y: 0.31), controlPoint2: CGPoint(x: 0.54, y: 0.28))
    nose.close()
    fillPath(nose)

    // Leaves above head.
    func addLeaf(center: CGPoint, size: CGSize, rotationDegrees: CGFloat) -> (outline: NSBezierPath, vein: NSBezierPath) {
        let outline = NSBezierPath()
        outline.move(to: CGPoint(x: 0, y: -1))
        outline.curve(to: CGPoint(x: 0.85, y: 0.0), controlPoint1: CGPoint(x: 0.55, y: -0.95), controlPoint2: CGPoint(x: 0.85, y: -0.45))
        outline.curve(to: CGPoint(x: 0, y: 1), controlPoint1: CGPoint(x: 0.85, y: 0.45), controlPoint2: CGPoint(x: 0.55, y: 0.95))
        outline.curve(to: CGPoint(x: -0.85, y: 0.0), controlPoint1: CGPoint(x: -0.55, y: 0.95), controlPoint2: CGPoint(x: -0.85, y: 0.45))
        outline.curve(to: CGPoint(x: 0, y: -1), controlPoint1: CGPoint(x: -0.85, y: -0.45), controlPoint2: CGPoint(x: -0.55, y: -0.95))
        outline.close()

        let vein = NSBezierPath()
        vein.move(to: CGPoint(x: 0, y: -0.82))
        vein.line(to: CGPoint(x: 0, y: 0.82))

        var t = AffineTransform.identity
        t.translate(x: center.x, y: center.y)
        t.rotate(byDegrees: rotationDegrees)
        t.scale(x: size.width / 2.0, y: size.height / 2.0)

        outline.transform(using: t)
        vein.transform(using: t)
        return (outline, vein)
    }

    let leafMid = addLeaf(center: CGPoint(x: 0.50, y: 0.93), size: CGSize(width: 0.14, height: 0.22), rotationDegrees: 0)
    let leafLeft = addLeaf(center: CGPoint(x: 0.39, y: 0.89), size: CGSize(width: 0.12, height: 0.18), rotationDegrees: -25)
    let leafRight = addLeaf(center: CGPoint(x: 0.61, y: 0.89), size: CGSize(width: 0.12, height: 0.18), rotationDegrees: 25)

    strokePath(leafMid.outline, color: style.leafStroke)
    strokePath(leafLeft.outline, color: style.leafStroke)
    strokePath(leafRight.outline, color: style.leafStroke)

    let veinWidth = max(lw * 0.55, 0.5 / rect.width) // ensure visibility at tiny pixel sizes
    strokePath(leafMid.vein, color: style.leafStroke, width: veinWidth)
    strokePath(leafLeft.vein, color: style.leafStroke, width: veinWidth)
    strokePath(leafRight.vein, color: style.leafStroke, width: veinWidth)

    context.restoreGState()
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

        // Handy previews.
        let appPreview = cwd.appendingPathComponent("output/icon-preview-app-512.png")
        try renderPNG(size: 512, kind: .app, to: appPreview)

        // Menubar preview composited on light/dark backgrounds to make the template icon visible in docs.
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
