// Forja: entry point. The command line needs no window; anything else starts the app.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only

import AppKit

// Forja was called Wyrmhold up to 1.1: the first time, its settings come over (a new bundle identifier means a new,
// empty settings domain). Before anything reads them.
do {
    let d = UserDefaults.standard
    let id = Bundle.main.bundleIdentifier ?? "io.github.gabriel-castiglia.forja"
    if (d.persistentDomain(forName: id) ?? [:]).isEmpty,
       let old = d.persistentDomain(forName: "io.github.gabriel-castiglia.wyrm" + "hold"), !old.isEmpty,
       !CommandLine.arguments.contains("--self-test"), !CommandLine.arguments.contains("--screenshot") {
        d.setPersistentDomain(old, forName: id)
    }
}

if CLI.wanted(CommandLine.arguments) {
    exit(CLI.run(CommandLine.arguments))
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
