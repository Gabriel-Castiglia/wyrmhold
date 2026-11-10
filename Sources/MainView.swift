// Wyrmhold: the main window.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The layout of the Windows version: a band with the icon, the kind of password and the
// profile, a card with the settings and the strength, a card with the list, a status line.

import AppKit
import SwiftUI

struct MainView: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        VStack(spacing: 0) {
            Band(m: m)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ModeSwitch(m: m)
                    ProfileMenu(m: m).frame(maxWidth: .infinity)
                }
                Card(p: p) { SettingsCard(m: m) }
                Card(p: p) { ListCard(m: m) }.frame(maxHeight: .infinity)
            }
            .padding(16)
            .frame(maxHeight: .infinity)
            StatusLine(m: m)
        }
        .background(p.page.color)
        .foregroundStyle(p.text.color)
        .tint(p.accent.color)
        .frame(minWidth: 680, minHeight: 640)
    }
}

// MARK: pieces

struct Card<Content: View>: View {
    let p: Palette
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(p.card.color))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(p.border.color))
    }
}

struct Band: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        HStack(spacing: 12) {
            if let img = Icon.image(accent: m.accent) {
                Image(nsImage: img).resizable().interpolation(.high).frame(width: 52, height: 52)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(m.T(.appTitle)).font(.system(size: 20, weight: .semibold)).foregroundStyle(p.bandText.color)
                Text(m.T(.appSubtitle)).font(.system(size: 12)).foregroundStyle(p.bandSub.color)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(LinearGradient(colors: [p.band.color, p.band2.color], startPoint: .leading, endPoint: .trailing))
    }
}

struct ModeSwitch: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        let items: [(Int, S, S)] = [(Int(PW_CHARS), .modeChars, .tipModeChars), (Int(PW_WORDS), .modeWords, .tipModeWords),
                                      (Int(PW_PIN), .modePin, .tipModePin)]
        HStack(spacing: 2) {
            ForEach(items, id: \.0) { mode, title, tip in
                let on = m.choices.mode == mode
                Button { m.choices.mode = mode } label: {
                    Text(m.T(title))
                        .font(.system(size: 13, weight: on ? .semibold : .regular))
                        .frame(minWidth: 92)
                        .padding(.vertical, 5)
                        .foregroundStyle(on ? p.onAccent.color : p.text.color)
                        .background(RoundedRectangle(cornerRadius: 6).fill(on ? p.accent.color : Color.clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(m.T(tip))
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 8).fill(p.card.color))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(p.border.color))
        .fixedSize()
    }
}

/// A menu-style text: the label, then the hint after its tab, dimmed.
struct HintLabel: View {
    let title: String
    let hint: String
    var body: some View {
        if hint.isEmpty { Text(title) } else { Text("\(title)   \(hint)") }
    }
}

struct ProfileMenu: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let current = m.currentPreset
        Menu {
            ForEach(Preset.allCases, id: \.rawValue) { pr in
                Button { m.apply(pr) } label: {
                    if current == pr { Image(systemName: "checkmark") }
                    HintLabel(title: m.label(pr.title), hint: m.hint(pr.title))
                }
            }
        } label: {
            Text(m.format(.profileFmt, current.map { m.label($0.title) } ?? m.label(.presetCustom)))
        }
        .help(m.T(.tipProfile))
    }
}

struct NumberField: View {
    let value: Int
    let range: ClosedRange<Int>
    let set: (Int) -> Void
    /// @State needs a compiler plugin that comes only with Xcode; a small object does the same.
    final class Box: ObservableObject { @Published var text = "" }
    @StateObject private var box = Box()
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $box.text)
            .multilineTextAlignment(.center)
            .frame(width: 46)
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .onAppear { box.text = String(value) }
            .onChange(of: value) { _, v in if !focused { box.text = String(v) } }
            .onSubmit(commit)
            .onChange(of: focused) { _, f in if !f { commit() } }
    }

    private func commit() {
        let v = max(range.lowerBound, min(range.upperBound, Int(box.text.trimmingCharacters(in: .whitespaces)) ?? value))
        box.text = String(v)
        if v != value { set(v) }
    }
}

struct SettingsCard: View {
    @ObservedObject var m: AppModel

    private var mode: Int { m.choices.mode }

    var body: some View {
        let p = m.palette
        VStack(alignment: .leading, spacing: 12) {
            lengthRow
            if mode == Int(PW_CHARS) { charsRows } else if mode == Int(PW_WORDS) { wordsRows } else { pinRows }
            Divider()
            HStack(alignment: .center) {
                StrengthView(m: m)
                Spacer(minLength: 12)
                Button { m.generate() } label: {
                    Text(m.T(.generate)).font(.system(size: 13, weight: .semibold))
                        .frame(minWidth: 120).padding(.vertical, 7)
                        .foregroundStyle(p.onAccent.color)
                        .background(RoundedRectangle(cornerRadius: 7).fill(p.accent.color))
                }
                .buttonStyle(.plain)
                .help(m.T(.tipGenerate))
            }
        }
    }

    private var lengthRow: some View {
        let (lo, hi, sliderHi, value, label): (Int, Int, Int, Int, S) =
            mode == Int(PW_WORDS) ? (Int(PW_MIN_WORDS), Int(PW_MAX_WORDS), Int(PW_MAX_WORDS), m.choices.words, .lblWords)
            : mode == Int(PW_PIN) ? (Int(PW_MIN_LEN), Int(PW_MAX_LEN), 20, m.choices.pinLength, .lblDigits)
            : (Int(PW_MIN_LEN), Int(PW_MAX_LEN), 64, m.choices.length, .lblLength)
        let set: (Int) -> Void = { v in
            if mode == Int(PW_WORDS) { m.choices.words = v } else if mode == Int(PW_PIN) { m.choices.pinLength = v } else { m.choices.length = v }
        }
        return HStack(spacing: 10) {
            Text(m.T(label)).frame(width: 84, alignment: .leading)
            Slider(value: Binding(get: { Double(min(value, sliderHi)) }, set: { set(Int($0.rounded())) }),
                   in: Double(lo) ... Double(sliderHi), step: 1)
            NumberField(value: value, range: lo ... hi, set: set)
            Text(m.T(.lblCount)).padding(.leading, 12)
            NumberField(value: m.count, range: 1 ... 50) { m.count = $0 }
            Stepper("", value: $m.count, in: 1 ... 50).labelsHidden()
        }
    }

    private var charsRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(m.T(.lblInclude)).frame(width: 84, alignment: .leading)
                Chip(m: m, title: .chipLower, on: $m.choices.lower)
                Chip(m: m, title: .chipUpper, on: $m.choices.upper)
                Chip(m: m, title: .chipDigits, on: $m.choices.digits)
                Chip(m: m, title: .chipSymbols, on: $m.choices.symbols)
                Spacer(minLength: 12)
                Text(m.T(.lblSymbols))
                Menu {
                    ForEach(Array([S.symBasic, .symAll, .symMin, .symCustom].enumerated()), id: \.offset) { i, s in
                        Button { m.choices.symbolSet = i } label: {
                            if m.choices.symbolSet == i { Image(systemName: "checkmark") }
                            HintLabel(title: m.label(s), hint: m.hint(s))
                        }
                    }
                } label: { Text(m.label([S.symBasic, .symAll, .symMin, .symCustom][m.choices.symbolSet])) }
                .frame(width: 150)
                .disabled(!m.choices.symbols)
                .help(m.T(.tipSymset))
            }
            .help(m.T(.tipChips))
            HStack(spacing: 18) {
                Toggle(m.T(.optAmbig), isOn: $m.choices.avoidAmbiguous).help(m.T(.tipAmbig))
                Toggle(m.T(.optNorepeat), isOn: $m.choices.charNoRepeat).help(m.T(.tipNorepeat))
                Toggle(m.T(.optStart), isOn: $m.choices.startLetter).help(m.T(.tipStart))
            }
            .toggleStyle(.switch).controlSize(.small)
            HStack(spacing: 10) {
                Text(m.T(.lblExclude)).frame(width: 84, alignment: .leading)
                TextField("", text: $m.choices.charExclude).frame(width: 150).textFieldStyle(.roundedBorder)
                    .help(m.T(.tipExclude))
                if m.choices.symbolSet == Int(PW_SYM_CUSTOM) && m.choices.symbols {
                    Text(m.T(.lblCustom)).padding(.leading, 12)
                    TextField("", text: $m.choices.customSymbols).frame(width: 150).textFieldStyle(.roundedBorder)
                        .help(m.T(.tipCustom))
                }
            }
        }
    }

    private var wordsRows: some View {
        let seps: [S] = [.sepHyphen, .sepSpace, .sepDot, .sepUnderscore, .sepNone, .sepDigit]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(m.T(.lblSeparator)).frame(width: 84, alignment: .leading)
                Menu {
                    ForEach(Array(seps.enumerated()), id: \.offset) { i, s in
                        Button { m.choices.separator = i } label: {
                            if m.choices.separator == i { Image(systemName: "checkmark") }
                            HintLabel(title: m.label(s), hint: m.hint(s))
                        }
                    }
                } label: { Text(m.label(seps[m.choices.separator])) }
                .frame(width: 170)
                .help(m.T(.tipSeparator))
                Spacer()
            }
            HStack(spacing: 18) {
                Toggle(m.T(.optCap), isOn: $m.choices.capitalize).help(m.T(.tipCap))
                Toggle(m.T(.optNumber), isOn: $m.choices.addNumber).help(m.T(.tipNumber))
            }
            .toggleStyle(.switch).controlSize(.small)
            Text(m.T(.wordsNote)).font(.system(size: 11)).foregroundStyle(m.palette.hint.color)
        }
    }

    private var pinRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 18) {
                Toggle(m.T(.optNorepeat), isOn: $m.choices.pinNoRepeat).help(m.T(.tipNorepeat))
                Toggle(m.T(.optNoseq), isOn: $m.choices.noSequence).help(m.T(.tipNoseq))
            }
            .toggleStyle(.switch).controlSize(.small)
            HStack(spacing: 10) {
                Text(m.T(.lblExclude)).frame(width: 84, alignment: .leading)
                TextField("", text: $m.choices.pinExclude).frame(width: 150).textFieldStyle(.roundedBorder)
                    .help(m.T(.tipExclude))
            }
            Text(m.T(.pinNote)).font(.system(size: 11)).foregroundStyle(m.palette.hint.color)
        }
    }
}

struct Chip: View {
    @ObservedObject var m: AppModel
    let title: S
    @Binding var on: Bool

    var body: some View {
        let p = m.palette
        Button { on.toggle() } label: {
            HStack(spacing: 3) {
                if on { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)) }
                Text(m.T(title))
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .foregroundStyle(on ? p.accent.color : p.hint.color)
            .background(RoundedRectangle(cornerRadius: 7).fill(on ? p.accentSoft.color : p.field.color))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(on ? p.accent.color : p.fieldBorder.color, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

struct StrengthView: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        let (code, which) = m.check
        if code != Int32(PW_OK) {
            let classes: [S] = [.classLower, .classUpper, .classDigits, .classSymbols]
            let id: S = code == Int32(PW_ERR_NOCLASS) ? .errNoclass : code == Int32(PW_ERR_EMPTYCLASS) ? .errEmptyclass
                : code == Int32(PW_ERR_NODIGITS) ? .errNodigits : .errTooshort
            let arg = which >= 0 && which < 4 ? m.T(classes[Int(which)]) : ""
            Text(m.format(id, arg)).font(.system(size: 13, weight: .semibold)).foregroundStyle(p.err.color)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            let bits = m.entropy
            let level = m.strengthLevel(bits)
            let pin = m.choices.mode == Int(PW_PIN)
            // A PIN is weak by design and safe only where tries are limited: said so, not in red.
            let lc = pin ? p.warn : level <= 1 ? p.err : level == 2 ? p.warn : p.ok
            let words: [S] = [.strVweak, .strWeak, .strFair, .strStrong, .strVstrong]
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0 ..< 5, id: \.self) { i in
                        Capsule().fill(i <= level ? lc.color : p.track.color).frame(width: 24, height: 6)
                    }
                    Text(m.T(pin ? .strPin : words[level])).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(lc.color).padding(.leading, 6)
                    Text(m.format(.strengthBits, Int32(bits.rounded()))).font(.system(size: 13))
                }
                Text(m.format(m.choices.mode == Int(PW_WORDS) ? .strengthDetailW : .strengthDetail,
                              Int32(m.pool), m.T(m.guessTime(bits))))
                    .font(.system(size: 11)).foregroundStyle(p.hint.color)
            }
            .help(m.T(.tipStrength))
        }
    }
}

struct ListCard: View {
    @ObservedObject var m: AppModel
    @FocusState private var focused: Bool

    var body: some View {
        let p = m.palette
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(m.T(.cardList)).font(.system(size: 13, weight: .semibold))
                Spacer()
                Toggle(m.T(.optClear), isOn: $m.clearClipboard).toggleStyle(.switch).controlSize(.small)
                    .help(m.T(.tipClear))
                Button { m.saveAll() } label: { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(.borderless).help(m.T(.tipSave)).disabled(m.passwords.isEmpty)
                Button { m.copyAll() } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless).help(m.T(.tipCopyall)).disabled(m.passwords.isEmpty)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(m.passwords.enumerated()), id: \.offset) { i, pw in
                            Row(m: m, index: i, password: pw).id(i)
                        }
                    }
                }
                .onChange(of: m.selected) { _, s in if let s { proxy.scrollTo(s) } }
            }
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(.upArrow) { move(-1) }
            .onKeyPress(.downArrow) { move(1) }
            .onKeyPress(.return) {
                if let s = m.selected { m.copy(s) }
                return .handled
            }
        }
        .foregroundStyle(p.text.color)
    }

    private func move(_ d: Int) -> KeyPress.Result {
        guard !m.passwords.isEmpty else { return .ignored }
        m.selected = max(0, min(m.passwords.count - 1, (m.selected ?? -1) + d))
        return .handled
    }
}

struct Row: View {
    @ObservedObject var m: AppModel
    let index: Int
    let password: String

    var body: some View {
        let p = m.palette
        let sel = m.selected == index
        HStack(spacing: 10) {
            Text("\(index + 1)").font(.system(size: 11, design: .monospaced)).foregroundStyle(p.hint.color)
                .frame(width: 22, alignment: .trailing)
            Text(coloured(p)).font(.system(size: 13, design: .monospaced)).textSelection(.disabled)
                .lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 8)
            Button { m.copy(index) } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.borderless).foregroundStyle(p.hint.color).help(m.extra(.copyOne))
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(sel ? p.accentSoft.color : Color.clear))
        .overlay(alignment: .leading) {
            if sel { RoundedRectangle(cornerRadius: 1.5).fill(p.accent.color).frame(width: 3).padding(.vertical, 4) }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { m.selected = index; m.copy(index) }
        .onTapGesture { m.selected = index }
    }

    /// Digits in blue and symbols in amber, so a password is easier to read back; what is
    /// copied is plain text.
    private func coloured(_ p: Palette) -> AttributedString {
        var out = AttributedString()
        for ch in password {
            var piece = AttributedString(String(ch))
            if ch.isASCII && ch.isNumber { piece.foregroundColor = p.digit.color }
            else if ch.isASCII && !ch.isLetter && !ch.isWhitespace { piece.foregroundColor = p.symbol.color }
            out += piece
        }
        return out
    }
}

struct StatusLine: View {
    @ObservedObject var m: AppModel

    var body: some View {
        let p = m.palette
        HStack {
            Text(m.status).font(.system(size: 12)).foregroundStyle(p.ok.color).lineLimit(1)
            Spacer()
            Text("v" + appVersion).font(.system(size: 11)).foregroundStyle(p.hint.color)
        }
        .padding(.horizontal, 16).padding(.vertical, 6)
        .background(p.card.color)
        .overlay(alignment: .top) { Rectangle().fill(p.border.color).frame(height: 1) }
    }
}

let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
let appRepo = "github.com/Gabriel-Castiglia/wyrmhold"
