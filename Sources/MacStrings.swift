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
]

extension AppModel {
    func extra(_ x: X) -> String { MAC_STRINGS[x.rawValue][lang.rawValue] }
}
