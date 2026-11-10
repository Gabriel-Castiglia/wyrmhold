// Wyrmhold: theme (light, dark or as macOS) and the twelve accent colours.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The colours are the ones of the Windows version: each accent has a deeper tone for the
// light theme, a brighter one for the dark, and the colour of the icon's tile. Black, the
// first one, is the default.

import AppKit
import SwiftUI

struct RGB: Equatable {
    let r, g, b: Double
    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
    init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }
    var luminance: Double { 0.2126 * r + 0.7152 * g + 0.0722 * b }

    func mix(_ o: RGB, _ t: Double) -> RGB {
        RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
    }
}

struct Accent {
    let name: S
    let light, dark, tile: RGB
}

let ACCENTS: [Accent] = [
    Accent(name: .accentBlack,  light: RGB(0x1F2937), dark: RGB(0xD1D5DB), tile: RGB(0x22242C)),
    Accent(name: .accentBlue,   light: RGB(0x2563EB), dark: RGB(0x60A5FA), tile: RGB(0x2F6FE0)),
    Accent(name: .accentGold,   light: RGB(0x9A6F00), dark: RGB(0xE0B03C), tile: RGB(0xB8860B)),
    Accent(name: .accentPurple, light: RGB(0x6D28D9), dark: RGB(0xA78BFA), tile: RGB(0x6D28D9)),
    Accent(name: .accentSky,    light: RGB(0x0284C7), dark: RGB(0x38BDF8), tile: RGB(0x0EA5E9)),
    Accent(name: .accentEmber,  light: RGB(0xC2410C), dark: RGB(0xFB923C), tile: RGB(0xEA580C)),
    Accent(name: .accentRed,    light: RGB(0xB91C1C), dark: RGB(0xF87171), tile: RGB(0xDC2626)),
    Accent(name: .accentYellow, light: RGB(0xA16207), dark: RGB(0xFACC15), tile: RGB(0xEAB308)),
    Accent(name: .accentGreen,  light: RGB(0x15803D), dark: RGB(0x4ADE80), tile: RGB(0x16A34A)),
    Accent(name: .accentTeal,   light: RGB(0x0F766E), dark: RGB(0x2DD4BF), tile: RGB(0x0D9488)),
    Accent(name: .accentPink,   light: RGB(0xBE185D), dark: RGB(0xF472B6), tile: RGB(0xDB2777)),
    Accent(name: .accentWhite,  light: RGB(0x475569), dark: RGB(0xF1F5F9), tile: RGB(0xF1F5F9)),
]

/// 0 as macOS, 1 light, 2 dark.
enum ThemeChoice: Int, CaseIterable { case system = 0, light = 1, dark = 2 }

/// Every colour the window paints, for one theme and accent.
struct Palette {
    let page, card, border, text, hint, field, fieldBorder, track: RGB
    let ok, warn, err, digit, symbol: RGB
    let accent, onAccent, accentSoft, band, band2, bandText, bandSub: RGB

    init(dark: Bool, accent index: Int) {
        let ac = ACCENTS[max(0, min(ACCENTS.count - 1, index))]
        let a = dark ? ac.dark : ac.light
        // The band takes the icon's tile colour, so the icon sits on its own colour; a white
        // tile would make the band grey, so it takes the deeper accent tone instead.
        let t = ac.tile.luminance > 0.8 ? ac.light : ac.tile
        if dark {
            page = RGB(0x15181D); card = RGB(0x1E2228); border = RGB(0x2D333B)
            text = RGB(0xE6E8EB); hint = RGB(0x98A2AE); field = RGB(0x262B32)
            fieldBorder = RGB(0x3A414B); track = RGB(0x3A414B)
            ok = RGB(0x4ADE80); warn = RGB(0xF0B44C); err = RGB(0xFF7B72)
            digit = RGB(0x79B8FF); symbol = RGB(0xF0B44C)
            band = t.mix(RGB(0x0B0E12), 0.62)
        } else {
            page = RGB(0xF3F5F8); card = RGB(0xFFFFFF); border = RGB(0xE1E5EB)
            text = RGB(0x1F2328); hint = RGB(0x5F6975); field = RGB(0xF7F8FA)
            fieldBorder = RGB(0xCBD2DA); track = RGB(0xD9DEE5)
            ok = RGB(0x1A7F37); warn = RGB(0xB54708); err = RGB(0xB42318)
            digit = RGB(0x1F5FBF); symbol = RGB(0xB54708)
            band = t.mix(RGB(0x0E1520), 0.50)
        }
        self.accent = a
        onAccent = a.luminance > 0.55 ? RGB(0x111418) : RGB(0xFFFFFF)
        accentSoft = card.mix(a, dark ? 0.20 : 0.11)
        band2 = band.mix(t, 0.35)
        bandText = RGB(0xFFFFFF)
        bandSub = RGB(0xFFFFFF).mix(band, 0.32)
    }
}

/// Whether macOS itself is in dark mode, read from the app's effective appearance when the
/// theme follows the system.
func systemIsDark() -> Bool {
    let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
    return match == .darkAqua
}
