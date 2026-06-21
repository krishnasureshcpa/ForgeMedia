// scripts/render_icon.swift — Render a 1024x1024 ForgeMedia app icon PNG.
// Uses Core Graphics only. No AppKit. Produces a flat Apple-neutral icon:
//   - #f5f5f7 rounded square base
//   - #0066cc accent (sparse, calm)
//   - Stylized "FM" monogram in #1d1d1f (Apple-neutral ink)
// Usage: swift scripts/render_icon.swift /tmp/forgemedia_icon_1024.png

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: render_icon.swift <output.png>\n".utf8))
    exit(2)
}
let outPath = args[1]

func makeContext(size: Int) -> CGContext? {
    let cs = CGColorSpaceCreateDeviceRGB()
    return CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
}

let px = 1024
guard let ctx = makeContext(size: px) else { exit(3) }

// Background: Apple-neutral rounded square #f5f5f7
let bgColor = CGColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1.0)
ctx.setFillColor(bgColor)

// Rounded rect mask: Apple "squircle-ish" corner radius ~ 22.37% (per macOS app icon standard).
let cornerRadius = CGFloat(px) * 0.2237
let fullRect = CGRect(x: 0, y: 0, width: px, height: px)
let bgPath = CGPath(roundedRect: fullRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
ctx.addPath(bgPath)
ctx.fillPath()

// Accent: a single, sparse blue square in the upper-left (the "media slot")
// #0066cc, ~22% width, ~6% height, anchored with safe-area padding.
let accentColor = CGColor(red: 0/255, green: 102/255, blue: 204/255, alpha: 1.0)
ctx.setFillColor(accentColor)
let accentInset = CGFloat(px) * 0.12
let accentW = CGFloat(px) * 0.28
let accentH = CGFloat(px) * 0.06
let accentRect = CGRect(
    x: accentInset,
    y: CGFloat(px) - accentInset - accentH,
    width: accentW,
    height: accentH
)
ctx.fill(accentRect)

// FM monogram — drawn with two stacked bars per letter, geometric.
// F: vertical bar + two horizontal arms
// M: two vertical bars + V in the middle (drawn as a polygon)
let ink = CGColor(red: 29/255, green: 29/255, blue: 31/255, alpha: 1.0)
ctx.setFillColor(ink)

let monogramTopY = CGFloat(px) * 0.30
let monogramHeight = CGFloat(px) * 0.40
let monogramBottomY = monogramTopY + monogramHeight
let stroke = CGFloat(px) * 0.085

// F — left letter
let fLeft = CGFloat(px) * 0.20
let fRight = fLeft + stroke
let fMidY = monogramTopY + monogramHeight * 0.55

// F vertical
ctx.fill(CGRect(x: fLeft, y: monogramTopY, width: stroke, height: monogramHeight))
// F top arm
ctx.fill(CGRect(x: fLeft, y: monogramTopY, width: stroke * 2.4, height: stroke))
// F mid arm
ctx.fill(CGRect(x: fLeft, y: fMidY, width: stroke * 1.9, height: stroke))

// M — right letter
let mLeft = CGFloat(px) * 0.50
let mRight = CGFloat(px) * 0.78
let mStroke = (mRight - mLeft) * 0.18

// M left vertical
ctx.fill(CGRect(x: mLeft, y: monogramTopY, width: mStroke, height: monogramHeight))
// M right vertical
ctx.fill(CGRect(x: mRight - mStroke, y: monogramTopY, width: mStroke, height: monogramHeight))
// M middle V — two diagonals approximated as filled polygons
let vTopLeft = mLeft + mStroke
let vTopRight = mRight - mStroke
let vApexX = (vTopLeft + vTopRight) / 2
let vApexY = monogramTopY + monogramHeight * 0.45

ctx.beginPath()
ctx.move(to: CGPoint(x: vTopLeft, y: monogramTopY))
ctx.addLine(to: CGPoint(x: vTopLeft + mStroke, y: monogramTopY))
ctx.addLine(to: CGPoint(x: vApexX + mStroke * 0.5, y: vApexY))
ctx.addLine(to: CGPoint(x: vApexX - mStroke * 0.5, y: vApexY))
ctx.closePath()
ctx.fillPath()

ctx.beginPath()
ctx.move(to: CGPoint(x: vTopRight, y: monogramTopY))
ctx.addLine(to: CGPoint(x: vTopRight - mStroke, y: monogramTopY))
ctx.addLine(to: CGPoint(x: vApexX + mStroke * 0.5, y: vApexY))
ctx.addLine(to: CGPoint(x: vApexX - mStroke * 0.5, y: vApexY))
ctx.closePath()
ctx.fillPath()

// Export as PNG
guard let cgImage = ctx.makeImage() else { exit(4) }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(5) }
CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else { exit(6) }
print("wrote \(outPath) (\(px)x\(px) PNG)")