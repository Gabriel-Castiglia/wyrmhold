# Changelog

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
