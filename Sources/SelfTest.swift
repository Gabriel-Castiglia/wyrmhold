// Wyrmhold: --self-test, the checks the command line cannot reach.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The rules of the passwords and the entropy are checked from outside, through the command
// line, by tools/check_options.py. This covers the rest: the text tables, the icon layer, the
// profiles, the passwords the window shows and the clipboard. The user's clipboard is saved
// first and put back at the end. Prints one line per check; exit 0 when all pass.

import AppKit
import SwiftUI

enum SelfTest {
    private static var failures = 0

    private static func check(_ name: String, _ ok: Bool, _ detail: @autoclosure () -> String = "") {
        if !ok { failures += 1 }
        let line = "\(ok ? "ok  " : "FAIL") \(name)\(ok ? "" : ": " + detail())\n"
        FileHandle.standardError.write(Data(line.utf8))
    }

    private static func specifiers(_ s: String) -> [String] {
        let re = try! NSRegularExpression(pattern: "%[0-9.*]*[@dsf]")
        return re.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { String(s[Range($0.range, in: s)!]) }
    }

    static func run(model m: AppModel) -> Bool {
        failures = 0

        // Text tables: one row per case, three languages, nothing empty, the same %-arguments.
        check("strings: one row per text", STRINGS.count == S.allCases.count, "\(STRINGS.count) rows, \(S.allCases.count) cases")
        check("mac strings: one row per text", MAC_STRINGS.count == X.allCases.count)
        for (i, row) in (STRINGS + MAC_STRINGS).enumerated() {
            if row.count != 3 || row.contains(where: { $0.isEmpty }) { check("strings: row \(i) complete", false, "\(row)") }
            else if Set(row.map(specifiers)).count != 1 { check("strings: row \(i) arguments", false, "\(row.map(specifiers))") }
        }
        check("strings: complete and consistent", failures == 0)
        let windowsWords = ["Windows", "Ctrl", "Win+", "BCrypt", "APPDATA", ".exe", ".ini"]
        let stray = STRINGS.flatMap { $0 }.filter { s in windowsWords.contains { s.contains($0) } }
        check("strings: nothing left from Windows", stray.isEmpty, stray.first ?? "")

        // Icon: the layer loads and lays on each tile colour.
        var iconOK = true
        for i in ACCENTS.indices {
            guard let img = Icon.image(accent: i), let rep = img.representations.first as? NSBitmapImageRep,
                  rep.pixelsWide == 1024 else { iconOK = false; continue }
            // the tile shows pure where nothing is drawn: inside the left edge, half way down
            guard let px = rep.bitmapData else { iconOK = false; continue }
            let at = (600 * 1024 + 120) * 4
            let t = ACCENTS[i].tile
            let got = (Double(px[at]), Double(px[at + 1]), Double(px[at + 2]), Double(px[at + 3]))
            if got.3 != 255 || abs(got.0 - t.r * 255) > 1 || abs(got.1 - t.g * 255) > 1 || abs(got.2 - t.b * 255) > 1 {
                iconOK = false
                check("icon tile \(i)", false, "\(got) vs \(t)")
            }
        }
        check("icon: twelve colours from the layer", iconOK)

        // Profiles: applying one is recognised as that one.
        for p in Preset.allCases {
            m.apply(p)
            check("profile \(p)", m.currentPreset == p, "\(String(describing: m.currentPreset))")
        }

        // The window's passwords follow the standard profile.
        m.apply(.standard)
        m.count = 50
        m.generate()
        let amb = Set("0O1lI|`'\"")
        let basic = Set("!@#$%&*+-=?")
        let good = m.passwords.allSatisfy { pw in
            pw.count == 20 && pw.contains(where: \.isLowercase) && pw.contains(where: \.isUppercase) &&
                pw.contains(where: \.isNumber) && pw.contains(where: { basic.contains($0) }) &&
                !pw.contains(where: { amb.contains($0) }) &&
                pw.allSatisfy { $0.isLetter || $0.isNumber || basic.contains($0) }
        }
        check("standard: 50 passwords that follow the rules", m.passwords.count == 50 && good)
        check("standard: all different", Set(m.passwords).count == m.passwords.count)
        let bits = m.entropy
        check("standard: about 122 bits", bits > 121 && bits < 123, "\(bits)")
        // Passphrase, separated by spaces: the EFF list has a word with a hyphen ("drop-down").
        m.apply(.phrase)
        m.choices.separator = Int(PW_SEP_SPACE)
        let words = Set((0 ..< Int(pw_word_count())).map { String(cString: pw_word(Int32($0))).lowercased() })
        let badPhrase = m.passwords.first { pw in
            let parts = pw.split(separator: " ", omittingEmptySubsequences: false)
            let digits = pw.filter(\.isNumber).count
            return parts.count != 6 || digits != 1 ||
                !parts.allSatisfy { words.contains($0.filter { !$0.isNumber }.lowercased()) && $0.first?.isUppercase == true }
        }
        check("passphrase: six listed words, capitals, one digit", m.passwords.count == 50 && badPhrase == nil,
              badPhrase ?? "\(m.passwords.count) passwords")
        m.apply(.pin)
        check("PIN: six digits", m.passwords.allSatisfy { $0.count == 6 && $0.allSatisfy(\.isNumber) })
        var c = m.choices
        c.mode = Int(PW_CHARS); c.lower = false; c.upper = false; c.digits = false; c.symbols = false
        m.choices = c
        check("no kind of character: no passwords and a message", m.passwords.isEmpty && m.status == m.T(.stNothing))

        // The main window resizes freely above its smallest size.
        if let w = NSApp.windows.first(where: { $0.contentView is NSHostingView<MainView> }) {
            w.setContentSize(NSSize(width: 700, height: 660))
            let small = w.contentRect(forFrameRect: w.frame).size
            w.setContentSize(NSSize(width: 900, height: 760))
            let big = w.contentRect(forFrameRect: w.frame).size
            check("window: resizes in both directions", abs(small.height - 660) < 2 && abs(big.height - 760) < 2 &&
                  abs(small.width - 700) < 2 && abs(big.width - 900) < 2, "\(small) \(big)")
        } else { check("window: main window found", false) }

        // Clipboard: concealed, wiped only while it still holds our copy.
        let pb = NSPasteboard.general
        let saved: [NSPasteboardItem] = (pb.pasteboardItems ?? []).map { old in
            let item = NSPasteboardItem()
            for t in old.types { if let d = old.data(forType: t) { item.setData(d, forType: t) } }
            return item
        }
        let cb = Clipboard.shared
        let sample = "Wyrmhold-self-test-\(arc4random())"
        check("clipboard: copy", cb.copy(sample, clearLater: false) && pb.string(forType: .string) == sample)
        check("clipboard: marked concealed", pb.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")) == true)
        check("clipboard: wiped when still ours", cb.wipeIfOurs() && pb.string(forType: .string) == nil)
        _ = cb.copy(sample, clearLater: false)
        pb.clearContents(); pb.setString("someone else", forType: .string)
        check("clipboard: left alone after another copy", !cb.wipeIfOurs() && pb.string(forType: .string) == "someone else")
        pb.clearContents()
        if !saved.isEmpty { pb.writeObjects(saved) }

        FileHandle.standardError.write(Data((failures == 0 ? "self-test: all passed\n" : "self-test: \(failures) failed\n").utf8))
        return failures == 0
    }
}
