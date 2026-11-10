// Wyrmhold: the Theme and colour, Help and About windows.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only

import AppKit
import SwiftUI

let appDate = Bundle.main.object(forInfoDictionaryKey: "WyrmholdDate") as? String ?? ""

struct ThemeView: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        VStack(alignment: .leading, spacing: 14) {
            Text(m.T(.themeAppearance)).font(.system(size: 13, weight: .semibold))
            Picker("", selection: $m.theme) {
                Text(m.T(.themeAuto)).tag(ThemeChoice.system)
                Text(m.T(.themeLight)).tag(ThemeChoice.light)
                Text(m.T(.themeDark)).tag(ThemeChoice.dark)
            }
            .pickerStyle(.segmented).labelsHidden().fixedSize()
            Text(m.T(.themeColour)).font(.system(size: 13, weight: .semibold)).padding(.top, 6)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(88), spacing: 8), count: 6), spacing: 12) {
                ForEach(ACCENTS.indices, id: \.self) { i in
                    let on = m.accent == i
                    Button { m.accent = i } label: {
                        VStack(spacing: 4) {
                            if let img = Icon.image(accent: i) {
                                Image(nsImage: img).resizable().interpolation(.high).frame(width: 52, height: 52)
                            }
                            Text(m.T(ACCENTS[i].name)).font(.system(size: 11)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .padding(5)
                        .frame(width: 88)
                        .background(RoundedRectangle(cornerRadius: 8).fill(on ? p.accentSoft.color : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? p.accent.color : Color.clear, lineWidth: 2))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(width: 608, alignment: .leading)
        .background(p.page.color)
        .foregroundStyle(p.text.color)
        .tint(p.accent.color)
    }
}

struct HelpView: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(m.T(.helpBody).components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    if line.hasPrefix("# ") {
                        Text(String(line.dropFirst(2))).font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(p.accent.color).padding(.top, 8)
                    } else if line.hasPrefix("\u{2022} ") {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\u{2022}")
                            Text(String(line.dropFirst(2))).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 6)
                    } else if !line.isEmpty {
                        Text(line).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(.system(size: 13))
            .textSelection(.enabled)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520, minHeight: 400)
        .background(p.card.color)
        .foregroundStyle(p.text.color)
    }
}

struct AboutView: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        VStack(spacing: 12) {
            if let img = Icon.image(accent: m.accent) {
                Image(nsImage: img).resizable().interpolation(.high).frame(width: 96, height: 96)
            }
            Text(m.T(.aboutName)).font(.system(size: 22, weight: .semibold))
            Text(m.format(.aboutVersion, appVersion, appDate)).font(.system(size: 12)).foregroundStyle(p.hint.color)
            Text(m.T(.aboutMeaning)).italic()
            Text(m.T(.aboutBody))
            Text(m.format(.aboutAuthor, "Gabriel Castiglia"))
            Link(appRepo, destination: URL(string: "https://" + appRepo)!)
            Text(m.T(.aboutCredits)).font(.system(size: 11)).foregroundStyle(p.hint.color)
            Text(m.T(.aboutLicense)).font(.system(size: 11)).foregroundStyle(p.hint.color)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .font(.system(size: 13))
        .padding(24)
        .frame(width: 520)
        .background(p.page.color)
        .foregroundStyle(p.text.color)
        .tint(p.accent.color)
    }
}
