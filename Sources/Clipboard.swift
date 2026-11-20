// Wyrmhold: copying passwords, and wiping them from the clipboard.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 20, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// Every copy is
//   - for this Mac only (NSPasteboard.ContentsOptions.currentHostOnly): Universal Clipboard
//     never sends it to the user's other devices;
//   - marked org.nspasteboard.ConcealedType, the convention clipboard managers follow to
//     leave a password out of their history (nspasteboard.org).
// With "Clear clipboard after" on, the copy is wiped when the chosen time is up (2 minutes by
// default), or at once when the app quits (the session ending too). It is wiped only while the
// clipboard still holds exactly what Wyrmhold put there: the pasteboard's change count, or else a
// SHA-256 of its text (the text itself is never kept). The same text put back by a clipboard tool
// is still wiped; anything else copied afterwards is left alone.

import AppKit
import CryptoKit

final class Clipboard {
    static let shared = Clipboard()
    /// The choices of the drop-down, in seconds; 2 minutes unless the user picks another.
    static let choices = [10, 30, 60, 120, 300, 600]
    static let defaultSeconds = 120
    static let range = 5...3600
    var seconds = Clipboard.defaultSeconds

    private var ownChange: Int?
    private var ownHash: Data?
    private var timer: Timer?
    private(set) var secondsLeft = 0
    /// Called every second while a wipe is pending, and once when it happens (left = 0).
    var onTick: ((_ left: Int, _ cleared: Bool) -> Void)?

    private static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    private static func digest(_ s: String) -> Data { Data(SHA256.hash(data: Data(s.utf8))) }

    @discardableResult
    func copy(_ text: String, clearLater: Bool) -> Bool {
        let pb = NSPasteboard.general
        pb.prepareForNewContents(with: .currentHostOnly)
        guard pb.setString(text, forType: .string) else { return false }
        pb.setString("", forType: Clipboard.concealed)
        ownChange = pb.changeCount
        ownHash = Clipboard.digest(text)
        timer?.invalidate()
        timer = nil
        secondsLeft = 0
        if clearLater {
            secondsLeft = min(max(seconds, Clipboard.range.lowerBound), Clipboard.range.upperBound)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        }
        return true
    }

    /// Whether the clipboard still holds our copy. Something else changed it but put back exactly our
    /// text (a clipboard tool, say): it stays ours, under its new change count.
    func stillOurs() -> Bool {
        let pb = NSPasteboard.general
        guard let own = ownChange, let hash = ownHash else { return false }
        if pb.changeCount == own { return true }
        guard let s = pb.string(forType: .string), Clipboard.digest(s) == hash else { return false }
        ownChange = pb.changeCount
        return true
    }

    private func tick() {
        guard stillOurs() else {
            stop()          // the user copied something else: leave it alone
            onTick?(0, false)
            return
        }
        secondsLeft -= 1
        if secondsLeft <= 0 {
            let cleared = wipeIfOurs()
            stop()
            onTick?(0, cleared)
        } else {
            onTick?(secondsLeft, false)
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        secondsLeft = 0
        ownChange = nil
        ownHash = nil
    }

    /// Clears the clipboard if it still holds our copy. Returns whether it did.
    @discardableResult
    func wipeIfOurs() -> Bool {
        guard stillOurs() else { return false }
        NSPasteboard.general.clearContents()
        ownChange = nil
        ownHash = nil
        return true
    }

    /// At quit: a copy waiting to be wiped goes now, if it is still ours. With clearing off nothing
    /// is waiting, and copies stay.
    func wipeAtQuit() {
        if secondsLeft > 0 { wipeIfOurs() }
        stop()
    }

    /// "10 s", "2 min": how a number of seconds reads in the drop-down.
    static func label(_ secs: Int, seconds s: String, minutes m: String) -> String {
        secs % 60 == 0 ? String(format: m, secs / 60) : String(format: s, secs)
    }

    /// "/clearafter:" or "-clearafter:" values: 90, 90s, 2m, off. nil = not valid; 0 = off.
    static func parse(_ v: String) -> Int? {
        let t = v.trimmingCharacters(in: .whitespaces).lowercased()
        if t == "off" || t == "0" { return 0 }
        var mult = 1, num = Substring(t)
        if num.hasSuffix("m") { mult = 60; num = num.dropLast() } else if num.hasSuffix("s") { num = num.dropLast() }
        guard let n = Int(num), n > 0 else { return nil }
        let secs = n * mult
        return range.contains(secs) ? secs : nil
    }
}
