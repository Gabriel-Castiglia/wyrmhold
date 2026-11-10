// Wyrmhold: passwords from the command line, with no window.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The same switches as the Windows version, written with a dash:
//
//   Wyrmhold.app/Contents/MacOS/Wyrmhold -out:FILE [-count:N] [options]
//   Wyrmhold.app/Contents/MacOS/Wyrmhold -entropy:FILE [options]
//
//   -mode:chars|words|pin  -len:N  -words:N  -count:N  -classes:luds
//   -symbols:basic|all|min|custom:LIST  -exclude:LIST  -ambiguous  -norepeat  -startletter
//   -sep:hyphen|space|dot|underscore|none|digit  -nocap  -nonumber  -allowruns  -preset:N
//
// -out writes N passwords (5 by default, at most 100000), one per line; -entropy writes
// "bits pool check". Without options they follow the standard profile, whatever the app's
// settings say, and nothing is read from or written to the preferences. Exit codes: 0 done,
// 2 the file could not be written, 3 the random number generator failed, 5 impossible options.

import Foundation

enum CLI {
    /// The value of `-key:`, or nil. A leading "/" is accepted too, as on Windows.
    static func value(_ key: String, in args: [String]) -> String? {
        for a in args.dropFirst() where a.hasPrefix("-") || a.hasPrefix("/") {
            let body = String(a.dropFirst())
            if body.lowercased().hasPrefix(key) { return String(body.dropFirst(key.count)) }
        }
        return nil
    }

    static func wanted(_ args: [String]) -> Bool {
        value("out:", in: args) != nil || value("entropy:", in: args) != nil
    }

    /// Runs the command line and returns the exit code.
    static func run(_ args: [String]) -> Int32 {
        var o = PwOptions()
        pw_defaults(&o)
        var noRepeat = false, count = 5, preset = -1, len = -1
        var exclude = ""

        for a in args.dropFirst() where a.hasPrefix("-") || a.hasPrefix("/") {
            let raw = String(a.dropFirst()), low = raw.lowercased()
            func after(_ p: String) -> String { String(raw.dropFirst(p.count)) }
            if low.hasPrefix("mode:") {
                let m = after("mode:").lowercased()
                o.mode = Int32(m == "words" ? PW_WORDS : m == "pin" ? PW_PIN : PW_CHARS)
            } else if low.hasPrefix("len:") { len = Int(after("len:")) ?? 0 }
            else if low.hasPrefix("words:") { o.words = Int32(Int(after("words:")) ?? 0) }
            else if low.hasPrefix("count:") { count = Int(after("count:")) ?? 0 }
            else if low.hasPrefix("classes:") {
                let c = after("classes:")
                o.lower = c.contains("l") ? 1 : 0; o.upper = c.contains("u") ? 1 : 0
                o.digits = c.contains("d") ? 1 : 0; o.symbols = c.contains("s") ? 1 : 0
            } else if low.hasPrefix("symbols:custom:") {
                o.symbolSet = Int32(PW_SYM_CUSTOM)
                setCString(&o.customSymbols, after("symbols:custom:"))
            } else if low == "symbols:all" { o.symbolSet = Int32(PW_SYM_ALL) }
            else if low == "symbols:min" { o.symbolSet = Int32(PW_SYM_MIN) }
            else if low == "symbols:basic" { o.symbolSet = Int32(PW_SYM_BASIC) }
            else if low.hasPrefix("exclude:") { exclude = after("exclude:") }
            else if low == "ambiguous" { o.avoidAmbiguous = 0 }
            else if low == "norepeat" { noRepeat = true }
            else if low == "startletter" { o.startLetter = 1 }
            else if low.hasPrefix("sep:") {
                let names = ["hyphen", "space", "dot", "underscore", "none", "digit"]
                if let k = names.firstIndex(of: after("sep:").lowercased()) { o.separator = Int32(k) }
            } else if low == "nocap" { o.capitalize = 0 }
            else if low == "nonumber" { o.addNumber = 0 }
            else if low == "allowruns" { o.noSequence = 0 }
            else if low.hasPrefix("preset:") { preset = Int(after("preset:")) ?? -1 }
        }
        if len > 0 { if o.mode == Int32(PW_PIN) { o.pinLength = Int32(len) } else { o.length = Int32(len) } }
        if let p = Preset(rawValue: preset) { (o, noRepeat) = p.options }
        o.noRepeat = noRepeat ? 1 : 0
        setCString(&o.exclude, exclude)

        if let path = value("entropy:", in: args) {
            let line = String(format: "%.6f %d %d\n", pw_entropy(&o), pw_pool(&o), pw_check(&o, nil))
            return write(line, to: path) ? 0 : 2
        }
        guard let path = value("out:", in: args) else { return 2 }
        guard FileManager.default.createFile(atPath: path, contents: nil, attributes: [.posixPermissions: 0o600]),
              let h = FileHandle(forWritingAtPath: path) else { return 2 }
        defer { try? h.close() }
        guard pw_check(&o, nil) == Int32(PW_OK) else { return 5 }
        var out = [CChar](repeating: 0, count: Int(PW_OUT_MAX))
        defer { memset_s(&out, out.count, 0, out.count) }
        for _ in 0 ..< max(1, min(100_000, count)) {
            let n = Int(pw_make(&o, &out))
            guard n > 0 else { return 3 }
            var line = out.prefix(n).map { UInt8(bitPattern: $0) }
            line.append(10)
            do { try h.write(contentsOf: line) } catch { return 2 }
        }
        return 0
    }

    private static func write(_ s: String, to path: String) -> Bool {
        (try? s.write(toFile: path, atomically: false, encoding: .utf8)) != nil
    }
}
