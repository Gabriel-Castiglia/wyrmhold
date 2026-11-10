// Wyrmhold: start-up, menus and windows.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// An AppKit application with SwiftUI content. The menus are built here, in the app's own
// language (English, Japanese or Spanish, switched at run time), not in the Mac's.
//
// Besides the window, the program answers to:
//   -out: / -entropy:          passwords or their entropy to a file, no window (CLI.swift)
//   --self-test                checks the parts that the command line does not reach
//   --screenshot FILE          draws one window into a PNG and quits, for the manuals;
//                              with --view main|theme|help|about, --lang en|ja|es,
//                              --theme light|dark, --accent N, --mode chars|words|pin
// The last two never read or write the preferences.

import AppKit
import Combine
import SwiftUI

// MARK: copy and save

extension AppModel {
    private var clearSuffix: String { clearClipboard ? format(.stClearIn, Int32(Clipboard.seconds)) : "" }

    func copy(_ i: Int) {
        guard passwords.indices.contains(i) else { return }
        if Clipboard.shared.copy(passwords[i], clearLater: clearClipboard) {
            copiedStatus = format(.stCopied, Int32(i + 1))
            status = copiedStatus + clearSuffix
        } else {
            status = T(.stClipFail)
        }
    }

    func copyAll() {
        guard !passwords.isEmpty else { return }
        if Clipboard.shared.copy(passwords.joined(separator: "\n"), clearLater: clearClipboard) {
            copiedStatus = passwords.count == 1 ? format(.stCopied, Int32(1)) : format(.stCopiedAll, Int32(passwords.count))
            status = copiedStatus + clearSuffix
        } else {
            status = T(.stClipFail)
        }
    }

    /// The wipe countdown in the status line.
    func clipboardTick(left: Int, cleared: Bool) {
        if cleared { status = T(.stCleared) }
        else if left > 0, !copiedStatus.isEmpty { status = copiedStatus + format(.stClearIn, Int32(left)) }
    }

    /// Saves every password, one per line, readable by the user only.
    func saveAll() {
        guard !passwords.isEmpty else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = T(.saveDefname)
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let text = passwords.joined(separator: "\n") + "\n"
        let ok = FileManager.default.createFile(atPath: url.path, contents: Data(text.utf8),
                                                attributes: [.posixPermissions: 0o600])
        status = ok ? format(.stSaved, url.path) : T(.stSaveFail)
    }
}

// MARK: menus

/// A menu item that runs a closure.
final class ClosureItem: NSMenuItem {
    private let run: () -> Void
    var isOn: () -> Bool = { false }
    var enabledIf: () -> Bool = { true }

    init(_ title: String, key: String = "", mods: NSEvent.ModifierFlags = .command, _ run: @escaping () -> Void) {
        self.run = run
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        keyEquivalentModifierMask = mods
        target = self
    }

    required init(coder: NSCoder) { fatalError("not used") }

    @objc private func fire() { run() }
}

final class MenuStates: NSObject, NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        for case let item as ClosureItem in menu.items {
            item.state = item.isOn() ? .on : .off
            item.isEnabled = item.enabledIf()
        }
    }

    func validate(_ item: NSMenuItem) -> Bool { (item as? ClosureItem)?.enabledIf() ?? true }
}

// MARK: application

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let m = AppModel.shared
    private var main: NSWindow?
    private var themeWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let states = MenuStates()
    private var bag: Set<AnyCancellable> = []
    private var appearanceWatch: NSKeyValueObservation?

    private func argument(after flag: String) -> String? {
        let a = CommandLine.arguments
        guard let i = a.firstIndex(of: flag), i + 1 < a.count else { return nil }
        return a[i + 1]
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        let shot = argument(after: "--screenshot")
        let selfTest = CommandLine.arguments.contains("--self-test")
        m.persist = shot == nil && !selfTest
        m.load()
        if shot != nil { applyShotArguments() }
        m.applyTheme()
        Icon.applyToDock(accent: m.accent)
        m.generate()
        m.status = m.T(.stReady)
        Clipboard.shared.onTick = { [weak self] left, cleared in self?.m.clipboardTick(left: left, cleared: cleared) }

        buildMenus()
        openMain(fixed: shot != nil)
        m.$lang.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in
            DispatchQueue.main.async { self?.languageChanged() }
        }.store(in: &bag)
        appearanceWatch = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async { self?.m.refreshDark() }
        }

        if selfTest {
            DispatchQueue.main.async { exit(SelfTest.run(model: self.m) ? 0 : 1) }
        } else if let path = shot {
            DispatchQueue.main.async { self.screenshot(view: self.argument(after: "--view") ?? "main", to: path) }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ note: Notification) {
        Clipboard.shared.wipeAtQuit(enabled: m.clearClipboard)
    }

    private func applyShotArguments() {
        if let l = argument(after: "--lang") { m.lang = ["en": .en, "ja": .ja, "jp": .ja, "es": .es][l] ?? .en }
        if let t = argument(after: "--theme") { m.theme = t == "dark" ? .dark : .light }
        if let a = argument(after: "--accent"), let n = Int(a) { m.accent = max(0, min(ACCENTS.count - 1, n)) }
        if let k = argument(after: "--mode") {
            m.choices.mode = Int(k == "words" ? PW_WORDS : k == "pin" ? PW_PIN : PW_CHARS)
        }
    }

    // MARK: windows

    private func openMain(fixed: Bool) {
        let host = NSHostingView(rootView: MainView(m: m))
        host.sizingOptions = [.minSize]      // the content sets the smallest size; the user, the rest
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 700),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered, defer: false)
        w.title = m.T(.windowTitle)
        w.contentView = host
        w.contentMinSize = NSSize(width: 680, height: 640)
        w.delegate = self
        if fixed || !w.setFrameUsingName("Main") { w.center() }
        if !fixed { w.setFrameAutosaveName("Main") }
        w.makeKeyAndOrderFront(nil)
        main = w
        NSApp.activate()
    }

    private func panel(_ title: S, size: NSSize, resizable: Bool = false, _ view: some View) -> NSWindow {
        let w = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                         styleMask: resizable ? [.titled, .closable, .resizable] : [.titled, .closable],
                         backing: .buffered, defer: false)
        w.title = m.T(title)
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: view)
        w.center()
        return w
    }

    func showTheme() {
        if themeWindow == nil { themeWindow = panel(.themeTitle, size: NSSize(width: 608, height: 420), ThemeView(m: m)) }
        themeWindow?.makeKeyAndOrderFront(nil)
    }

    func showHelp() {
        if helpWindow == nil {
            helpWindow = panel(.helpTitle, size: NSSize(width: 640, height: 620), resizable: true, HelpView(m: m))
        }
        helpWindow?.makeKeyAndOrderFront(nil)
    }

    func showAbout() {
        if aboutWindow == nil { aboutWindow = panel(.aboutTitle, size: NSSize(width: 520, height: 560), AboutView(m: m)) }
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    private func languageChanged() {
        main?.title = m.T(.windowTitle)
        themeWindow?.title = m.T(.themeTitle)
        helpWindow?.title = m.T(.helpTitle)
        aboutWindow?.title = m.T(.aboutTitle)
        buildMenus()
    }

    // MARK: menus

    private func top(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        menu.delegate = states
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private func item(_ title: String, key: String = "", mods: NSEvent.ModifierFlags = .command,
                      on: @escaping () -> Bool = { false }, enabled: @escaping () -> Bool = { true },
                      _ run: @escaping () -> Void) -> ClosureItem {
        let i = ClosureItem(title, key: key, mods: mods, run)
        i.isOn = on
        i.enabledIf = enabled
        return i
    }

    /// The menu bar, in the app's language.
    func buildMenus() {
        let t = m.T, l = m.label
        let name = "Wyrmhold"
        let bar = NSMenu()
        let x = m.extra

        bar.addItem(top(name, [
            item(x(.menuAboutApp)) { [weak self] in self?.showAbout() },
            .separator(),
            item(l(.menuThemedlg), key: ",") { [weak self] in self?.showTheme() },
            .separator(),
            item(x(.menuHide), key: "h") { NSApp.hide(nil) },
            item(x(.menuHideOthers), key: "h", mods: [.command, .option]) { NSApp.hideOtherApplications(nil) },
            item(x(.menuShowAll)) { NSApp.unhideAllApplications(nil) },
            .separator(),
            item(x(.menuQuit), key: "q") { NSApp.terminate(nil) },
        ]))

        let has = { [weak self] in !(self?.m.passwords.isEmpty ?? true) }
        bar.addItem(top(l(.menuFile), [
            item(l(.menuGenerate), key: "r") { [weak self] in self?.m.generate() },
            item(l(.menuCopyall), key: "c", mods: [.command, .shift], enabled: has) { [weak self] in self?.m.copyAll() },
            item(l(.menuSave), key: "s", enabled: has) { [weak self] in self?.m.saveAll() },
            .separator(),
            item(x(.menuClose), key: "w") { NSApp.keyWindow?.performClose(nil) },
        ]))

        // Edit: the text boxes get the usual commands; with the list in front, Copy copies the
        // selected password.
        let edit = { (sel: Selector) in { _ = NSApp.sendAction(sel, to: nil, from: nil) } }
        bar.addItem(top(x(.menuEdit), [
            item(x(.menuCut), key: "x", edit(#selector(NSText.cut(_:)))),
            item(x(.menuCopy), key: "c") { [weak self] in
                if NSApp.keyWindow?.firstResponder is NSText { _ = NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                else if let s = self?.m.selected, NSApp.keyWindow === self?.main { self?.m.copy(s) }
            },
            item(x(.menuPaste), key: "v", edit(#selector(NSText.paste(_:)))),
            item(x(.menuSelectAll), key: "a", edit(#selector(NSText.selectAll(_:)))),
        ]))

        var kinds: [NSMenuItem] = [
            item(l(.menuModeChars), key: "1", on: { [weak self] in self?.m.choices.mode == Int(PW_CHARS) }) { [weak self] in self?.m.choices.mode = Int(PW_CHARS) },
            item(l(.menuModeWords), key: "2", on: { [weak self] in self?.m.choices.mode == Int(PW_WORDS) }) { [weak self] in self?.m.choices.mode = Int(PW_WORDS) },
            item(l(.menuModePin), key: "3", on: { [weak self] in self?.m.choices.mode == Int(PW_PIN) }) { [weak self] in self?.m.choices.mode = Int(PW_PIN) },
            .separator(),
        ]
        for p in Preset.allCases {
            let h = m.hint(p.title)
            kinds.append(item(h.isEmpty ? l(p.title) : "\(l(p.title))  —  \(h)",
                              on: { [weak self] in self?.m.currentPreset == p }) { [weak self] in self?.m.apply(p) })
        }
        bar.addItem(top(l(.menuKind), kinds))

        bar.addItem(top(l(.menuView), [
            item(l(.menuThemeAuto), on: { [weak self] in self?.m.theme == .system }) { [weak self] in self?.m.theme = .system },
            item(l(.menuThemeLight), on: { [weak self] in self?.m.theme == .light }) { [weak self] in self?.m.theme = .light },
            item(l(.menuThemeDark), on: { [weak self] in self?.m.theme == .dark }) { [weak self] in self?.m.theme = .dark },
            .separator(),
            item(l(.menuThemedlg)) { [weak self] in self?.showTheme() },
        ]))

        bar.addItem(top(l(.menuLang), [
            item(t(.menuEn), on: { [weak self] in self?.m.lang == .en }) { [weak self] in self?.m.lang = .en },
            item(t(.menuJp), on: { [weak self] in self?.m.lang == .ja }) { [weak self] in self?.m.lang = .ja },
            item(t(.menuEs), on: { [weak self] in self?.m.lang == .es }) { [weak self] in self?.m.lang = .es },
        ]))

        let window = top(x(.menuWindow), [
            item(x(.menuMinimize), key: "m") { NSApp.keyWindow?.miniaturize(nil) },
            item(x(.menuZoom)) { NSApp.keyWindow?.zoom(nil) },
        ])
        bar.addItem(window)
        let help = top(l(.menuHelp), [
            item(l(.menuHelptopics), key: "?") { [weak self] in self?.showHelp() },
        ])
        bar.addItem(help)
        NSApp.mainMenu = bar
        NSApp.windowsMenu = window.submenu
        NSApp.helpMenu = help.submenu
    }

    // MARK: screenshots

    private func screenshot(view: String, to path: String) {
        var target = main
        switch view {
        case "theme": showTheme(); target = themeWindow
        case "help": showHelp(); target = helpWindow
        case "about": showAbout(); target = aboutWindow
        default: break
        }
        var frames = 0
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { timer in
            frames += 1
            target?.displayIfNeeded()
            guard frames >= 30 else { return }
            timer.invalidate()
            let ok = target.map { Self.savePicture(of: $0, to: path) } ?? false
            FileHandle.standardError.write(Data((ok ? "screenshot saved: \(path)\n" : "screenshot failed\n").utf8))
            exit(ok ? 0 : 1)
        }
    }

    private static func savePicture(of window: NSWindow, to path: String) -> Bool {
        guard let content = window.contentView else { return false }
        let view = content.superview ?? content
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return false }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? png.write(to: URL(fileURLWithPath: path))) != nil
    }
}
