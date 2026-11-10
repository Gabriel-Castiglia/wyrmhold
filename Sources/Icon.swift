// Wyrmhold: the icon in the colour of the chosen accent.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// assets/icon_layer.wyi, written by tools/make_icon.py, is the drawing without its tile:
// "WYI2", a little-endian uint16 size n, then raw DEFLATE of n * n pixels of five bytes,
// T K R G B, where the premultiplied pixel is  rgb = RGB + tile * K / 255,  alpha = T.
// Laying it on the tile colour of an accent gives the icon in that colour; the app shows it
// in the Dock, in the window band and in the About window. The icon in Finder is the
// default (black) one, made at build time: changing it would break the app's signature.

import AppKit

enum Icon {
    private static let layer: (n: Int, bytes: [UInt8])? = {
        guard let url = Bundle.main.url(forResource: "icon_layer", withExtension: "wyi"),
              let data = try? Data(contentsOf: url), data.count > 6,
              data.prefix(4) == Data("WYI2".utf8)
        else { return nil }
        let n = Int(data[4]) | Int(data[5]) << 8
        guard n > 0, let raw = try? (data.dropFirst(6) as NSData).decompressed(using: .zlib),
              raw.length == n * n * 5
        else { return nil }
        return (n, [UInt8](raw as Data))
    }()

    private static var cache: [Int: NSImage] = [:]

    /// The icon on the tile of accent `index`, at the layer's full size (1024 px).
    static func image(accent index: Int) -> NSImage? {
        if let hit = cache[index] { return hit }
        guard let (n, src) = layer else { return nil }
        let tile = ACCENTS[max(0, min(ACCENTS.count - 1, index))].tile
        let tr = tile.r * 255, tg = tile.g * 255, tb = tile.b * 255
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: n, pixelsHigh: n,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .calibratedRGB,
                                         bitmapFormat: [], bytesPerRow: n * 4, bitsPerPixel: 32),
              let out = rep.bitmapData
        else { return nil }
        // NSBitmapImageRep without .alphaNonpremultiplied holds premultiplied RGBA, as the layer does.
        for i in 0 ..< n * n {
            let q = i * 5, k = Double(src[q + 1]) / 255
            out[i * 4]     = UInt8(min(255, (Double(src[q + 2]) + tr * k).rounded()))
            out[i * 4 + 1] = UInt8(min(255, (Double(src[q + 3]) + tg * k).rounded()))
            out[i * 4 + 2] = UInt8(min(255, (Double(src[q + 4]) + tb * k).rounded()))
            out[i * 4 + 3] = src[q]
        }
        let image = NSImage(size: NSSize(width: n / 2, height: n / 2))
        image.addRepresentation(rep)
        cache[index] = image
        return image
    }

    /// Puts the icon of accent `index` in the Dock while the app runs.
    static func applyToDock(accent index: Int) {
        if let img = image(accent: index) { NSApp.applicationIconImage = img }
    }
}
