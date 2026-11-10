// Wyrmhold: the settings, the passwords on screen, profiles and strength.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The passwords themselves come from the C engine (Engine/pwgen.c), the same one as the
// Windows version; this file only keeps the choices, turns them into a PwOptions and shows
// the results. Settings are kept in the app's preferences under the names the Windows
// version uses in its .ini; the passwords are never written anywhere by the app.

import AppKit
import Combine

/// The choices on screen. The Windows version keeps "no repeats" and "leave out" apart for
/// characters and for PINs; so does this one.
struct Choices: Equatable {
    var mode = Int(PW_CHARS)
    var length = 20
    var lower = true, upper = true, digits = true, symbols = true
    var symbolSet = Int(PW_SYM_BASIC)
    var customSymbols = ""
    var avoidAmbiguous = true
    var charNoRepeat = false
    var startLetter = false
    var charExclude = ""
    var words = 6
    var separator = Int(PW_SEP_HYPHEN)
    var capitalize = true
    var addNumber = true
    var pinLength = 6
    var pinNoRepeat = true
    var noSequence = true
    var pinExclude = ""
}

enum Preset: Int, CaseIterable {
    case standard, maximum, noSymbols, minSymbols, short, wifi, phrase, pin

    var title: S {
        [.presetStandard, .presetMax, .presetNosym, .presetMinsym, .presetShort, .presetWifi,
         .presetPhrase, .presetPin][rawValue]
    }

    /// The profile as engine options plus its "no repeats" setting, as in the Windows version.
    var options: (PwOptions, Bool) {
        var o = PwOptions()
        pw_defaults(&o)
        var noRepeat = false
        switch self {
        case .standard: break
        case .maximum: o.length = 32; o.symbolSet = Int32(PW_SYM_ALL); o.avoidAmbiguous = 0
        case .noSymbols: o.symbols = 0
        case .minSymbols: o.symbolSet = Int32(PW_SYM_MIN); o.startLetter = 1
        case .short: o.length = 12; o.startLetter = 1; noRepeat = true
        case .wifi: o.upper = 0; o.symbols = 0
        case .phrase: o.mode = Int32(PW_WORDS)
        case .pin: o.mode = Int32(PW_PIN); noRepeat = true
        }
        return (o, noRepeat)
    }
}

/// Only printable ASCII symbols and letters make sense in the character boxes; the engine
/// ignores anything else, so it is dropped here too.
func asciiOnly(_ s: String) -> String {
    String(String.UnicodeScalarView(s.unicodeScalars.filter { $0.value > 32 && $0.value < 127 }))
}

/// Copies a Swift string into a fixed C char array, always zero-terminated.
func setCString<T>(_ field: inout T, _ s: String) {
    withUnsafeMutableBytes(of: &field) { buf in
        let bytes = Array(s.utf8.prefix(buf.count - 1))
        buf.copyBytes(from: bytes)
        buf[bytes.count] = 0
    }
}

func cString<T>(_ field: T) -> String {
    withUnsafeBytes(of: field) { buf in
        String(decoding: buf.prefix { $0 != 0 }, as: UTF8.self)
    }
}

final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var choices = Choices() { didSet { if choices != oldValue { optionsChanged() } } }
    @Published var count = 5 { didSet { if count != oldValue { save(); generate() } } }
    @Published var clearClipboard = true { didSet { save() } }
    @Published var theme = ThemeChoice.system { didSet { save(); applyTheme() } }
    @Published var accent = 0 { didSet { save(); Icon.applyToDock(accent: accent) } }
    @Published var lang = Lang.en { didSet { save(); status = T(.stReady) } }
    @Published private(set) var dark = false

    @Published private(set) var passwords: [String] = []
    @Published var selected: Int?
    @Published var status = ""
    /// The status line of the last copy, without the wipe countdown.
    var copiedStatus = ""

    /// Off for screenshots and tests: nothing is read from or written to the preferences.
    var persist = true
    private let defaults = UserDefaults.standard

    // MARK: text

    func T(_ s: S) -> String { STRINGS[s.rawValue][lang.rawValue] }

    /// The part of a menu-style text before its tab.
    func label(_ s: S) -> String { String(T(s).split(separator: "\t", omittingEmptySubsequences: false)[0]) }

    /// The hint after the tab, or "".
    func hint(_ s: S) -> String {
        let parts = T(s).split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
        return parts.count > 1 ? String(parts[1]) : ""
    }

    func format(_ s: S, _ args: CVarArg...) -> String { String(format: T(s), arguments: args) }

    var palette: Palette { Palette(dark: dark, accent: accent) }

    // MARK: options

    /// The engine options for the current choices, the way the Windows version builds them.
    func effective() -> PwOptions {
        var o = PwOptions()
        pw_defaults(&o)
        let c = choices
        o.mode = Int32(c.mode)
        o.length = Int32(c.length)
        o.lower = c.lower ? 1 : 0; o.upper = c.upper ? 1 : 0
        o.digits = c.digits ? 1 : 0; o.symbols = c.symbols ? 1 : 0
        o.symbolSet = Int32(c.symbolSet)
        setCString(&o.customSymbols, asciiOnly(c.customSymbols))
        o.avoidAmbiguous = c.avoidAmbiguous ? 1 : 0
        o.startLetter = c.startLetter ? 1 : 0
        o.words = Int32(c.words)
        o.separator = Int32(c.separator)
        o.capitalize = c.capitalize ? 1 : 0
        o.addNumber = c.addNumber ? 1 : 0
        o.pinLength = Int32(c.pinLength)
        o.noSequence = c.noSequence ? 1 : 0
        let pin = c.mode == Int(PW_PIN)
        o.noRepeat = (pin ? c.pinNoRepeat : c.charNoRepeat) ? 1 : 0
        setCString(&o.exclude, asciiOnly(pin ? c.pinExclude : c.charExclude))
        return o
    }

    /// Which profile the current settings are, or nil (custom). Only what matters for the
    /// current kind of password is compared.
    var currentPreset: Preset? {
        let e = effective()
        for p in Preset.allCases {
            let (o, nr) = p.options
            guard o.mode == e.mode else { continue }
            if e.mode == Int32(PW_WORDS) {
                if o.words == e.words && o.separator == e.separator && o.capitalize == e.capitalize && o.addNumber == e.addNumber { return p }
            } else if e.mode == Int32(PW_PIN) {
                if o.pinLength == e.pinLength && (nr ? 1 : 0) == e.noRepeat && o.noSequence == e.noSequence && cString(e.exclude).isEmpty { return p }
            } else if o.length == e.length && o.lower == e.lower && o.upper == e.upper && o.digits == e.digits &&
                      o.symbols == e.symbols && (o.symbolSet == e.symbolSet || e.symbols == 0) &&
                      o.avoidAmbiguous == e.avoidAmbiguous && (nr ? 1 : 0) == e.noRepeat &&
                      o.startLetter == e.startLetter && cString(e.exclude).isEmpty {
                return p
            }
        }
        return nil
    }

    func apply(_ p: Preset) {
        let (o, nr) = p.options
        var c = choices
        switch Int(o.mode) {
        case Int(PW_WORDS):
            c.mode = Int(PW_WORDS)
            c.words = Int(o.words); c.separator = Int(o.separator)
            c.capitalize = o.capitalize != 0; c.addNumber = o.addNumber != 0
        case Int(PW_PIN):
            c.mode = Int(PW_PIN)
            c.pinLength = Int(o.pinLength); c.noSequence = o.noSequence != 0
            c.pinNoRepeat = nr; c.pinExclude = ""
        default:
            c.mode = Int(PW_CHARS)
            c.length = Int(o.length)
            c.lower = o.lower != 0; c.upper = o.upper != 0; c.digits = o.digits != 0; c.symbols = o.symbols != 0
            c.symbolSet = Int(o.symbolSet); c.avoidAmbiguous = o.avoidAmbiguous != 0
            c.startLetter = o.startLetter != 0; c.charNoRepeat = nr; c.charExclude = ""
        }
        choices = c
    }

    private func optionsChanged() {
        save()
        generate()
    }

    // MARK: passwords

    /// PW_OK, or why no password can be made, with the class that ended up empty.
    var check: (code: Int32, which: Int32) {
        var o = effective()
        var which: Int32 = -1
        let code = pw_check(&o, &which)
        return (code, which)
    }

    var entropy: Double { var o = effective(); return pw_entropy(&o) }
    var pool: Int { var o = effective(); return Int(pw_pool(&o)) }

    /// A completely new set. Nothing is stored.
    func generate() {
        var o = effective()
        guard pw_check(&o, nil) == Int32(PW_OK) else {
            passwords = []; selected = nil
            status = T(.stNothing)
            return
        }
        var out = [CChar](repeating: 0, count: Int(PW_OUT_MAX))
        var list: [String] = []
        for _ in 0 ..< count {
            guard pw_make(&o, &out) > 0 else {
                passwords = []; selected = nil
                status = T(.stRngFail)
                memset_s(&out, out.count, 0, out.count)
                return
            }
            list.append(String(cString: out))
        }
        memset_s(&out, out.count, 0, out.count)
        passwords = list
        selected = list.isEmpty ? nil : 0
        status = list.count == 1 ? T(.stGeneratedOne) : format(.stGenerated, Int32(list.count))
    }

    // MARK: strength

    /// Guessing time for an attacker who has the file and tries 100 billion passwords a
    /// second; on average half the space is searched.
    func guessTime(_ bits: Double) -> S {
        let secs = pow(2.0, bits - 1) / 1e11, year = 3.156e7
        if secs < 1 { return .timeInstant }
        if secs < 3600 { return .timeMinutes }
        if secs < 86400 { return .timeHours }
        if secs < year { return .timeDays }
        if secs < 100 * year { return .timeYears }
        if secs < 1e6 * year { return .timeCenturies }
        if secs < 1.4e10 * year { return .timeMillions }
        return .timeForever
    }

    func strengthLevel(_ bits: Double) -> Int {
        bits < 36 ? 0 : bits < 50 ? 1 : bits < 64 ? 2 : bits < 80 ? 3 : 4
    }

    // MARK: theme

    func applyTheme() {
        switch theme {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        refreshDark()
    }

    func refreshDark() {
        let d = theme == .dark || (theme == .system && systemIsDark())
        if d != dark { dark = d }
    }

    // MARK: preferences

    private var loading = false

    func load() {
        guard persist else { return }
        loading = true
        defer { loading = false }
        let d = defaults
        func int(_ k: String, _ def: Int, _ lo: Int, _ hi: Int) -> Int {
            d.object(forKey: k) == nil ? def : max(lo, min(hi, d.integer(forKey: k)))
        }
        func bool(_ k: String, _ def: Bool) -> Bool { d.object(forKey: k) == nil ? def : d.bool(forKey: k) }
        func str(_ k: String) -> String { asciiOnly(d.string(forKey: k) ?? "") }
        var c = Choices()
        c.mode = int("Mode", Int(PW_CHARS), Int(PW_CHARS), Int(PW_PIN))
        c.length = int("Length", 20, Int(PW_MIN_LEN), Int(PW_MAX_LEN))
        c.lower = bool("Lower", true); c.upper = bool("Upper", true)
        c.digits = bool("Digits", true); c.symbols = bool("Symbols", true)
        c.symbolSet = int("SymbolSet", Int(PW_SYM_BASIC), Int(PW_SYM_BASIC), Int(PW_SYM_CUSTOM))
        c.customSymbols = str("CustomSymbols")
        c.avoidAmbiguous = bool("AvoidAmbiguous", true)
        c.charNoRepeat = bool("NoRepeat", false)
        c.startLetter = bool("StartLetter", false)
        c.charExclude = str("Exclude")
        c.words = int("Words", 6, Int(PW_MIN_WORDS), Int(PW_MAX_WORDS))
        c.separator = int("Separator", Int(PW_SEP_HYPHEN), 0, Int(PW_SEP_COUNT) - 1)
        c.capitalize = bool("Capitalize", true)
        c.addNumber = bool("AddNumber", true)
        c.pinLength = int("PinLength", 6, Int(PW_MIN_LEN), Int(PW_MAX_LEN))
        c.pinNoRepeat = bool("PinNoRepeat", true)
        c.noSequence = bool("PinNoSequence", true)
        c.pinExclude = str("PinExclude")
        choices = c
        count = int("Count", 5, 1, 50)
        clearClipboard = bool("ClearClipboard", true)
        theme = ThemeChoice(rawValue: int("Theme", 0, 0, 2)) ?? .system
        accent = int("Accent", 0, 0, ACCENTS.count - 1)
        lang = Lang(rawValue: int("Language", AppModel.macLanguage.rawValue, 0, Lang.allCases.count - 1)) ?? .en
    }

    /// The first time, the app speaks the Mac's language if it is Japanese or Spanish.
    static var macLanguage: Lang {
        for code in Locale.preferredLanguages {
            if code.hasPrefix("ja") { return .ja }
            if code.hasPrefix("es") { return .es }
            if code.hasPrefix("en") { return .en }
        }
        return .en
    }

    func save() {
        guard persist, !loading else { return }
        let d = defaults, c = choices
        let values: [String: Any] = [
            "Mode": c.mode, "Length": c.length, "Count": count,
            "Lower": c.lower, "Upper": c.upper, "Digits": c.digits, "Symbols": c.symbols,
            "SymbolSet": c.symbolSet, "CustomSymbols": asciiOnly(c.customSymbols),
            "AvoidAmbiguous": c.avoidAmbiguous, "NoRepeat": c.charNoRepeat, "StartLetter": c.startLetter,
            "Exclude": asciiOnly(c.charExclude), "Words": c.words, "Separator": c.separator,
            "Capitalize": c.capitalize, "AddNumber": c.addNumber, "PinLength": c.pinLength,
            "PinNoRepeat": c.pinNoRepeat, "PinNoSequence": c.noSequence, "PinExclude": asciiOnly(c.pinExclude),
            "ClearClipboard": clearClipboard, "Theme": theme.rawValue, "Accent": accent, "Language": lang.rawValue,
        ]
        for (k, v) in values { d.set(v, forKey: k) }
    }
}
