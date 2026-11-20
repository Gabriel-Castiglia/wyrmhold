// Wyrmhold: the texts that only the Mac version has (the standard menu commands).
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// The menu bar follows the app's language, not the Mac's, so the standard commands are
// written here in the three languages, with the words macOS itself uses.

enum X: Int, CaseIterable {
    case menuAboutApp, menuHide, menuHideOthers, menuShowAll, menuQuit
    case menuClose, menuEdit, menuCut, menuCopy, menuPaste, menuSelectAll
    case menuWindow, menuMinimize, menuZoom
    case copyOne
    case tipClearTime, clearSeconds, clearMinutes, menuUpdate, menuUpdateAuto
}

let MAC_STRINGS: [[String]] = [
    ["About Wyrmhold", "Wyrmhold について", "Acerca de Wyrmhold"],
    ["Hide Wyrmhold", "Wyrmhold を非表示", "Ocultar Wyrmhold"],
    ["Hide Others", "ほかを非表示", "Ocultar otros"],
    ["Show All", "すべてを表示", "Mostrar todo"],
    ["Quit Wyrmhold", "Wyrmhold を終了", "Salir de Wyrmhold"],
    ["Close", "閉じる", "Cerrar"],
    ["Edit", "編集", "Edición"],
    ["Cut", "カット", "Cortar"],
    ["Copy", "コピー", "Copiar"],
    ["Paste", "ペースト", "Pegar"],
    ["Select All", "すべてを選択", "Seleccionar todo"],
    ["Window", "ウインドウ", "Ventana"],
    ["Minimize", "しまう", "Minimizar"],
    ["Zoom", "拡大/縮小", "Zoom"],
    ["Copy this password", "このパスワードをコピー", "Copiar esta contraseña"],
    ["How long a copied password stays on the clipboard. Choosing a time also switches clearing on.", "コピーしたパスワードをクリップボードに残す時間。時間を選ぶと自動消去もオンになります。", "Cuánto tiempo queda en el portapapeles una contraseña copiada. Elegir un tiempo también enciende el borrado."],
    ["%d s", "%d秒後", "%d s"],
    ["%d min", "%d分後", "%d min"],
    ["Check for Updates…", "アップデートを確認…", "Buscar actualizaciones…"],
    ["Check for Updates Daily", "毎日自動でアップデートを確認", "Buscar actualizaciones todos los días"],
]

extension AppModel {
    func extra(_ x: X) -> String { MAC_STRINGS[x.rawValue][lang.rawValue] }
}
