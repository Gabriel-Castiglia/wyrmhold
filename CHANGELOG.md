# Changelog

## 3.0.0 — 2026-11-20

**Wyrmhold is now Forja**, a name easier to remember: the forge, where metal takes shape under the hammer, as each
password here takes shape from pure chance. From this version the Mac and Windows versions share one number. The
icon is the anvil and hammers of the trade card of Elwell and Taylor, smiths of London (c. 1766, British Museum,
public domain). The repository is now `forja` (GitHub forwards the old address).

- The app is `/Applications/Forja.app`, with the identifier `io.github.gabriel-castiglia.forja`; the package is
  `Forja-<version>.pkg`, and installing it closes and removes Wyrmhold.
- The first time Forja starts, the settings of Wyrmhold come over.
- The texts of the update question name the app apart from its file name (shared with the other apps).

## 1.1.0 — 2026-11-20

What Wyrmhold 2.1.0 for Windows brought, on the Mac.

- Clipboard: copies are wiped after **2 minutes** by default (it was a fixed 30 seconds). A drop-down beside "Clear
  clipboard after" offers 10 s, 30 s, 1, 2, 5 and 10 minutes, and choosing a time switches clearing on; the switch
  still turns it off. The settings keep `ClearSeconds` (5 to 3600) beside `ClearClipboard`;
  `-clearafter:N[s|m]|off` sets it for one session without saving it.
- Clipboard: the copy is wiped only while the clipboard still holds exactly what Wyrmhold put there, by the
  pasteboard's change count or else a SHA-256 of its text (never the text itself). The same text put back by a
  clipboard tool is still wiped; anything else copied afterwards is left alone. Quitting (or the session ending)
  before the time is up wipes a pending copy at once; with clearing off, copies stay.
- Updates that install themselves: Help → Check for Updates, and a daily check (Help → Check for Updates Daily,
  `CheckUpdates`). One question (Update now, What's new, Later); then the package is downloaded, checked against the
  release's `SHA256SUMS.txt`, its app checked for the same identifier, version and signature, and swapped for the
  installed one as Wyrmhold quits; the new one opens.
- `--self-test` covers the new clipboard rules and the update's pure functions.
- Not brought over: the Windows window for small screens (the smallest Mac screen holds the window as it is).

## 1.0.0 — 2026-11-10

First version for macOS, made from Wyrmhold 2.0.1 for Windows.

- The same password engine in C, with the macOS cryptographic random number generator (`arc4random_buf`):
  characters, passphrases from the EFF list and PINs, uniform over every password that follows the rules, and the
  exact entropy.
- The same profiles, options, strength line and command-line switches as the Windows version (written with a
  dash), and the settings under the same names.
- A native window (AppKit and SwiftUI) in English, Japanese and Spanish, switched at run time; the first time it
  follows the language of the Mac. Menus with the macOS shortcuts (⌘1–⌘3, ⌘R, ⇧⌘C, ⌘S).
- Theme as macOS, light or dark, and the twelve colours of the Windows version, which also tint the icon in the
  Dock.
- Copies stay on this Mac (no Universal Clipboard), are marked as concealed for clipboard managers, and are wiped
  after 30 s or at quit if nothing else was copied in between.
- Installer package in English, Japanese and Spanish, for macOS 15 or later on Apple silicon.
- Checks: `--self-test`, and the independent option and uniformity checks of the Windows version adapted to the
  Mac.
