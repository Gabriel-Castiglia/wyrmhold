// Wyrmhold: copying passwords, and wiping them from the clipboard.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// Every copy is
//   - for this Mac only (NSPasteboard.ContentsOptions.currentHostOnly): Universal Clipboard
//     never sends it to the user's other devices;
//   - marked org.nspasteboard.ConcealedType, the convention clipboard managers follow to
//     leave a password out of their history (nspasteboard.org).
// With "Clear clipboard after 30 s" on, the copy is wiped 30 seconds later, or when the app
// quits, unless something else was copied in between (the pasteboard's change count tells).

import AppKit

final class Clipboard {
    static let shared = Clipboard()
    static let seconds = 30

    private var ownChange: Int?
    private var timer: Timer?
    private(set) var secondsLeft = 0
    /// Called every second while a wipe is pending, and once when it happens (left = 0).
    var onTick: ((_ left: Int, _ cleared: Bool) -> Void)?

    private static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    @discardableResult
    func copy(_ text: String, clearLater: Bool) -> Bool {
        let pb = NSPasteboard.general
        pb.prepareForNewContents(with: .currentHostOnly)
        guard pb.setString(text, forType: .string) else { return false }
        pb.setString("", forType: Clipboard.concealed)
        ownChange = pb.changeCount
        timer?.invalidate()
        timer = nil
        secondsLeft = 0
        if clearLater {
            secondsLeft = Clipboard.seconds
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        }
        return true
    }

    private func tick() {
        guard let own = ownChange, NSPasteboard.general.changeCount == own else {
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
    }

    /// Clears the clipboard if it still holds our copy. Returns whether it did.
    @discardableResult
    func wipeIfOurs() -> Bool {
        let pb = NSPasteboard.general
        guard let own = ownChange, pb.changeCount == own else { return false }
        pb.clearContents()
        ownChange = nil
        return true
    }

    /// At quit: wipe only when the user asked for wiping.
    func wipeAtQuit(enabled: Bool) {
        if enabled { wipeIfOurs() }
        stop()
    }
}
