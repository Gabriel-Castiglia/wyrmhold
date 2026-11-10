// Wyrmhold: every piece of text the app shows, in English, Japanese and Spanish.
// Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
// Date: November 10, 2026
// SPDX-License-Identifier: GPL-2.0-only
//
// One case per text and one row per case, three columns in the order of Lang. Nothing
// user-visible is written anywhere else. Conventions, as in the Windows version:
//   - a %d or %@ in one language is in the same order in the others;
//   - menu-style texts may carry a hint after a tab ("Basic\t! @ #"): menus show it on the
//     right, buttons show only the part before the tab;
//   - the help text: "# " starts a heading, "\u{2022} " a bullet.

import Foundation

enum Lang: Int, CaseIterable, Codable {
    case en = 0, ja = 1, es = 2
}

enum S: Int, CaseIterable {
    case windowTitle
    case appTitle
    case appSubtitle
    case modeChars
    case modeWords
    case modePin
    case tipModeChars
    case tipModeWords
    case tipModePin
    case profileFmt
    case tipProfile
    case presetStandard
    case presetMax
    case presetNosym
    case presetMinsym
    case presetShort
    case presetWifi
    case presetPhrase
    case presetPin
    case presetCustom
    case cardList
    case lblLength
    case lblWords
    case lblDigits
    case lblCount
    case lblInclude
    case lblSymbols
    case lblSeparator
    case lblExclude
    case lblCustom
    case chipLower
    case chipUpper
    case chipDigits
    case chipSymbols
    case tipChips
    case symBasic
    case symAll
    case symMin
    case symCustom
    case tipSymset
    case sepHyphen
    case sepSpace
    case sepDot
    case sepUnderscore
    case sepNone
    case sepDigit
    case tipSeparator
    case optAmbig
    case optNorepeat
    case optStart
    case optCap
    case optNumber
    case optNoseq
    case optClear
    case tipAmbig
    case tipNorepeat
    case tipStart
    case tipExclude
    case tipCustom
    case tipCap
    case tipNumber
    case tipNoseq
    case tipClear
    case wordsNote
    case pinNote
    case generate
    case tipGenerate
    case tipCopyall
    case tipSave
    case strVweak
    case strWeak
    case strFair
    case strStrong
    case strVstrong
    case strPin
    case strengthBits
    case strengthDetail
    case strengthDetailW
    case tipStrength
    case timeInstant
    case timeMinutes
    case timeHours
    case timeDays
    case timeYears
    case timeCenturies
    case timeMillions
    case timeForever
    case classLower
    case classUpper
    case classDigits
    case classSymbols
    case errNoclass
    case errEmptyclass
    case errTooshort
    case errNodigits
    case stReady
    case stGenerated
    case stGeneratedOne
    case stNothing
    case stCopied
    case stCopiedAll
    case stClearIn
    case stCleared
    case stSaved
    case stSaveFail
    case stClipFail
    case stRngFail
    case saveDefname
    case menuFile
    case menuGenerate
    case menuCopy
    case menuCopyall
    case menuSave
    case menuKind
    case menuModeChars
    case menuModeWords
    case menuModePin
    case menuView
    case menuThemeAuto
    case menuThemeLight
    case menuThemeDark
    case menuThemedlg
    case themeTitle
    case themeAppearance
    case themeAuto
    case themeLight
    case themeDark
    case themeColour
    case accentBlue
    case accentGold
    case accentPurple
    case accentSky
    case accentEmber
    case accentRed
    case accentYellow
    case accentGreen
    case accentTeal
    case accentPink
    case accentBlack
    case accentWhite
    case menuLang
    case menuEn
    case menuJp
    case menuEs
    case menuHelp
    case menuHelptopics
    case menuAbout
    case helpTitle
    case helpBody
    case btnOk
    case aboutTitle
    case aboutName
    case aboutMeaning
    case aboutVersion
    case aboutBody
    case aboutAuthor
    case aboutCredits
    case aboutLicense
}

let STRINGS: [[String]] = [
    ["Wyrmhold", "Wyrmhold", "Wyrmhold"],  // windowTitle
    ["Wyrmhold", "Wyrmhold", "Wyrmhold"],  // appTitle
    ["Strong passwords, passphrases and PINs — made here, stored nowhere", "強力なパスワード・パスフレーズ・PIN — ここで作り、どこにも保存しません", "Contraseñas, frases y PIN fuertes — se hacen acá y no se guardan en ningún lado"],  // appSubtitle
    ["Characters", "文字", "Caracteres"],  // modeChars
    ["Passphrase", "パスフレーズ", "Frase"],  // modeWords
    ["PIN", "PIN", "PIN"],  // modePin
    ["Random characters: the strongest per character (⌘1).", "ランダムな文字: 1文字あたり最も強力です (⌘1)。", "Caracteres al azar: lo más fuerte por carácter (⌘1)."],  // tipModeChars
    ["Random words: long but easy to remember and to type (⌘2).", "ランダムな単語: 長いが覚えやすく入力しやすい (⌘2)。", "Palabras al azar: más largas, pero fáciles de recordar y tipear (⌘2)."],  // tipModeWords
    ["Digits only, for locks, cards and phones (⌘3).", "数字のみ。錠前・カード・スマートフォン用 (⌘3)。", "Solo dígitos, para cerraduras, tarjetas y teléfonos (⌘3)."],  // tipModePin
    ["Profile: %@", "プロファイル: %@", "Perfil: %@"],  // profileFmt
    ["Ready-made settings for common cases: sites that refuse symbols, sites with a short maximum length, Wi-Fi, PIN…", "よくある用途向けの設定: 記号を受け付けないサイト、最大文字数が短いサイト、Wi-Fi、PIN など。", "Configuraciones listas para casos comunes: sitios que no aceptan símbolos, sitios con largo máximo corto, Wi-Fi, PIN…"],  // tipProfile
    ["Standard\t20 characters, basic symbols", "標準\t20文字、基本の記号", "Estándar\t20 caracteres, símbolos básicos"],  // presetStandard
    ["Maximum\t32 characters, every symbol", "最強\t32文字、すべての記号", "Máxima\t32 caracteres, todos los símbolos"],  // presetMax
    ["No symbols\tfor sites that refuse them", "記号なし\t記号を受け付けないサイト用", "Sin símbolos\tpara sitios que no los aceptan"],  // presetNosym
    ["Minimal symbols\tonly - _ .  for strict sites", "最小限の記号\t- _ . のみ、厳しいサイト用", "Símbolos mínimos\tsolo - _ .  para sitios estrictos"],  // presetMinsym
    ["Short\t12 characters, for a low maximum", "短め\t12文字、最大文字数が少ない場合", "Corta\t12 caracteres, para un máximo bajo"],  // presetShort
    ["Wi-Fi\teasy to type on a phone or TV", "Wi-Fi\tスマホやテレビで入力しやすい", "Wi-Fi\tfácil de tipear en un teléfono o TV"],  // presetWifi
    ["Passphrase\t6 words, easy to remember", "パスフレーズ\t6単語、覚えやすい", "Frase\t6 palabras, fácil de recordar"],  // presetPhrase
    ["PIN\t6 digits, no repeats or runs", "PIN\t6桁、繰り返し・連番なし", "PIN\t6 dígitos, sin repetidos ni seguidos"],  // presetPin
    ["Custom", "カスタム", "Personalizado"],  // presetCustom
    ["Passwords", "パスワード", "Contraseñas"],  // cardList
    ["Length", "文字数", "Largo"],  // lblLength
    ["Words", "単語数", "Palabras"],  // lblWords
    ["Digits", "桁数", "Dígitos"],  // lblDigits
    ["How many", "生成数", "Cantidad"],  // lblCount
    ["Use", "使う文字", "Usar"],  // lblInclude
    ["Symbols", "記号", "Símbolos"],  // lblSymbols
    ["Separator", "区切り", "Separador"],  // lblSeparator
    ["Leave out", "除外", "Excluir"],  // lblExclude
    ["My symbols", "使う記号", "Mis símbolos"],  // lblCustom
    ["a–z", "a–z", "a–z"],  // chipLower
    ["A–Z", "A–Z", "A–Z"],  // chipUpper
    ["0–9", "0–9", "0–9"],  // chipDigits
    ["#$%", "#$%", "#$%"],  // chipSymbols
    ["Which kinds of character to use. Every kind that is on appears at least once in each password.", "使う文字の種類。オンにした種類は、どのパスワードにも必ず1文字以上入ります。", "Qué tipos de carácter usar. Cada tipo encendido aparece al menos una vez en cada contraseña."],  // tipChips
    ["Basic\t! @ # $ % & * + - = ?", "基本\t! @ # $ % & * + - = ?", "Básicos\t! @ # $ % & * + - = ?"],  // symBasic
    ["All 32\tevery printable symbol", "全32種\t印字可能なすべての記号", "Los 32\ttodos los símbolos imprimibles"],  // symAll
    ["Minimal\t- _ .", "最小限\t- _ .", "Mínimos\t- _ ."],  // symMin
    ["My own…\ttype them in", "自分で指定…\t入力する", "Los míos…\tescribirlos"],  // symCustom
    ["Which symbols. Basic ones are accepted almost everywhere; Minimal (- _ .) suits strict sites; My own lets you type exactly the symbols a site allows.", "使う記号。基本の記号はほぼどこでも使えます。最小限 (- _ .) は厳しいサイト向け。自分で指定ではサイトが許可する記号だけを入力できます。", "Qué símbolos. Los básicos se aceptan casi en todos lados; los mínimos (- _ .) sirven para sitios estrictos; con «Los míos» escribís exactamente los que permite el sitio."],  // tipSymset
    ["Hyphen\t-", "ハイフン\t-", "Guion\t-"],  // sepHyphen
    ["Space", "スペース", "Espacio"],  // sepSpace
    ["Dot\t.", "ドット\t.", "Punto\t."],  // sepDot
    ["Underscore\t_", "アンダースコア\t_", "Guion bajo\t_"],  // sepUnderscore
    ["None", "なし", "Ninguno"],  // sepNone
    ["Random digit\t0–9, adds strength", "ランダムな数字\t0–9、強度が上がる", "Dígito al azar\t0–9, suma fuerza"],  // sepDigit
    ["What goes between the words. A random digit adds about 3.3 bits for every gap.", "単語の間に入れるもの。ランダムな数字にすると区切りごとに約3.3ビット強くなります。", "Qué va entre las palabras. Un dígito al azar suma unos 3,3 bits por cada espacio entre palabras."],  // tipSeparator
    ["No look-alikes  0 O 1 l I", "紛らわしい文字なし  0 O 1 l I", "Sin parecidos  0 O 1 l I"],  // optAmbig
    ["No repeats in a row", "同じ文字を連続させない", "Sin repetir seguidos"],  // optNorepeat
    ["Start with a letter", "英字で始める", "Empezar con letra"],  // optStart
    ["Capital letters", "大文字にする", "Mayúsculas"],  // optCap
    ["Add a digit", "数字を1つ入れる", "Agregar un dígito"],  // optNumber
    ["No runs like 123 or 987", "123 や 987 のような連番なし", "Sin seguidos tipo 123 o 987"],  // optNoseq
    ["Clear clipboard after 30 s", "30秒後にクリップボードを消去", "Borrar portapapeles a los 30 s"],  // optClear
    ["Leaves out 0, O, 1, l and I (and | ` ' \" among the symbols). They look alike in many fonts, so a password that is read out or typed by hand goes wrong less often.", "0、O、1、l、I(記号では | ` ' \")を使いません。多くのフォントで見分けにくいため、読み上げたり手で入力したりするときの間違いが減ります。", "Deja afuera 0, O, 1, l e I (y | ` ' \" entre los símbolos). Se parecen en muchas fuentes, así que una contraseña dictada o tipeada a mano falla menos."],  // tipAmbig
    ["Never the same character twice in a row (aa, 11). Some sites and devices refuse them.", "同じ文字を2回続けません (aa、11)。受け付けないサイトや機器があります。", "Nunca el mismo carácter dos veces seguidas (aa, 11). Algunos sitios y equipos no lo aceptan."],  // tipNorepeat
    ["The first character is always a letter. Some sites and older systems require it.", "最初の文字を必ず英字にします。これを求めるサイトや古いシステムがあります。", "El primer carácter es siempre una letra. Algunos sitios y sistemas viejos lo exigen."],  // tipStart
    ["Characters that must never appear, for example the ones a site refuses. Type them one after the other.", "絶対に使わない文字。たとえばサイトが受け付けない文字を続けて入力してください。", "Caracteres que nunca deben aparecer, por ejemplo los que un sitio rechaza. Escribilos uno detrás del otro."],  // tipExclude
    ["Exactly the symbols to use, for example the list a site says it accepts. Letters and digits typed here are ignored.", "使う記号そのもの。たとえばサイトが受け付けると書いている記号の一覧です。ここに入力した英字や数字は無視されます。", "Exactamente los símbolos a usar, por ejemplo la lista que el sitio dice aceptar. Letras y dígitos se ignoran acá."],  // tipCustom
    ["Each Word Starts With A Capital, for sites that require uppercase letters.", "各単語の先頭を大文字にします。大文字を必須とするサイト用です。", "Cada Palabra Empieza Con Mayúscula, para sitios que exigen mayúsculas."],  // tipCap
    ["One digit after one of the words, for sites that require a number.", "どれか1つの単語の後に数字を1つ入れます。数字を必須とするサイト用です。", "Un dígito después de una de las palabras, para sitios que exigen un número."],  // tipNumber
    ["No three digits in a row going up or down by one, such as 123 or 987: the first ones people try.", "123 や 987 のように1ずつ増減する3桁の並びを使いません。真っ先に試される番号だからです。", "Ningún trío de dígitos que suba o baje de a uno, como 123 o 987: son los primeros que se prueban."],  // tipNoseq
    ["30 seconds after you copy a password it is wiped from the clipboard, unless you have copied something else in between. Copies are marked as confidential, so clipboard managers leave them out, and they never go to your other devices through Universal Clipboard.", "パスワードをコピーしてから30秒後に、その間にほかのものをコピーしていなければ、クリップボードから消去します。コピーには機密の印が付くのでクリップボード管理アプリには記録されず、ユニバーサルクリップボードでほかのデバイスに送られることもありません。", "30 segundos después de copiar una contraseña se borra del portapapeles, salvo que hayas copiado otra cosa mientras tanto. Las copias van marcadas como confidenciales, así que los gestores de portapapeles no las guardan, y nunca pasan a tus otros dispositivos por el Portapapeles Universal."],  // tipClear
    ["Words from the EFF list of 7776 English words: each adds 12.9 bits.", "EFF の英単語リスト (7776語) から選びます。1語ごとに 12.9 ビット。", "Palabras de la lista EFF de 7776 palabras en inglés: cada una suma 12,9 bits."],  // wordsNote
    ["A PIN is only safe where wrong tries are limited (cards, phones, locks).", "PIN が安全なのは、誤入力の回数が制限される場合だけです (カード、スマホ、錠前)。", "Un PIN solo es seguro donde los intentos fallidos están limitados (tarjetas, teléfonos, cerraduras)."],  // pinNote
    ["Generate", "生成", "Generar"],  // generate
    ["A new set of passwords (⌘R). Nothing is stored.", "新しいパスワードを生成します (⌘R)。何も保存されません。", "Un juego nuevo de contraseñas (⌘R). No se guarda nada."],  // tipGenerate
    ["Copy all the passwords, one per line (⇧⌘C)", "すべてのパスワードを1行に1つずつコピー (⇧⌘C)", "Copiar todas las contraseñas, una por línea (⇧⌘C)"],  // tipCopyall
    ["Save all the passwords to a text file (⌘S)", "すべてのパスワードをテキストファイルに保存 (⌘S)", "Guardar todas las contraseñas en un archivo de texto (⌘S)"],  // tipSave
    ["Very weak", "非常に弱い", "Muy débil"],  // strVweak
    ["Weak", "弱い", "Débil"],  // strWeak
    ["Fair", "普通", "Aceptable"],  // strFair
    ["Strong", "強い", "Fuerte"],  // strStrong
    ["Very strong", "非常に強い", "Muy fuerte"],  // strVstrong
    ["PIN: only where tries are limited", "PIN: 試行回数が制限される場合のみ", "PIN: solo con intentos limitados"],  // strPin
    ["  ·  %d bits of entropy", "  ·  エントロピー %d ビット", "  ·  %d bits de entropía"],  // strengthBits
    ["%d possible characters per position  ·  guessing it: %@", "1文字あたり %d 種類  ·  推測にかかる時間: %@", "%d caracteres posibles por posición  ·  adivinarla: %@"],  // strengthDetail
    ["%d words in the list  ·  guessing it: %@", "リストの単語数 %d  ·  推測にかかる時間: %@", "%d palabras en la lista  ·  adivinarla: %@"],  // strengthDetailW
    ["The entropy counts exactly how many different passwords these settings can produce (every rule included): n bits means 2^n possibilities. The guessing time assumes an attacker with the file trying 100 billion a second. 80 bits or more is very strong.", "エントロピーは、この設定で作れるパスワードの数をすべての規則を含めて正確に数えたものです。n ビットは2^n 通りを意味します。推測時間は、ファイルを持つ攻撃者が毎秒1000億回試す場合の目安です。80ビット以上で非常に強力です。", "La entropía cuenta exactamente cuántas contraseñas distintas pueden salir con esta configuración (con todas las reglas): n bits son 2^n posibilidades. El tiempo supone un atacante con el archivo que prueba 100 mil millones por segundo. 80 bits o más es muy fuerte."],  // tipStrength
    ["instantly", "一瞬", "al instante"],  // timeInstant
    ["minutes", "数分", "minutos"],  // timeMinutes
    ["hours", "数時間", "horas"],  // timeHours
    ["days to months", "数日〜数か月", "días a meses"],  // timeDays
    ["years", "数年", "años"],  // timeYears
    ["centuries", "数世紀", "siglos"],  // timeCenturies
    ["millions of years", "数百万年", "millones de años"],  // timeMillions
    ["longer than the age of the universe", "宇宙の年齢より長い", "más que la edad del universo"],  // timeForever
    ["the lowercase letters", "小文字", "las minúsculas"],  // classLower
    ["the uppercase letters", "大文字", "las mayúsculas"],  // classUpper
    ["the digits", "数字", "los dígitos"],  // classDigits
    ["the symbols", "記号", "los símbolos"],  // classSymbols
    ["Turn on at least one kind of character.", "文字の種類を1つ以上オンにしてください。", "Encendé al menos un tipo de carácter."],  // errNoclass
    ["Nothing is left of %@: allow some, or turn that kind off.", "%@ が1文字も残っていません。除外を減らすか、その種類をオフにしてください。", "No queda nada de %@: permití alguno o apagá ese tipo."],  // errEmptyclass
    ["No password can follow all these rules. Relax one of them.", "すべての規則を満たすパスワードは作れません。どれかを緩めてください。", "Ninguna contraseña puede cumplir todas estas reglas. Aflojá alguna."],  // errTooshort
    ["Every digit is left out.", "すべての数字が除外されています。", "Están excluidos todos los dígitos."],  // errNodigits
    ["Ready.", "準備完了。", "Listo."],  // stReady
    ["%d new passwords.", "新しいパスワードを %d 個生成しました。", "%d contraseñas nuevas."],  // stGenerated
    ["1 new password.", "新しいパスワードを 1 個生成しました。", "1 contraseña nueva."],  // stGeneratedOne
    ["No passwords: see the message above the list.", "パスワードはありません。一覧の上のメッセージをご覧ください。", "No hay contraseñas: mirá el mensaje arriba de la lista."],  // stNothing
    ["Password %d copied to the clipboard.", "パスワード %d をクリップボードにコピーしました。", "Contraseña %d copiada al portapapeles."],  // stCopied
    ["%d passwords copied to the clipboard.", "%d 個のパスワードをクリップボードにコピーしました。", "%d contraseñas copiadas al portapapeles."],  // stCopiedAll
    ["  It will be cleared in %d s.", "  %d 秒後に消去します。", "  Se borra en %d s."],  // stClearIn
    ["The clipboard was cleared.", "クリップボードを消去しました。", "Se borró el portapapeles."],  // stCleared
    ["Saved: %@", "保存しました: %@", "Guardado: %@"],  // stSaved
    ["Could not write the file.", "ファイルに書き込めませんでした。", "No se pudo escribir el archivo."],  // stSaveFail
    ["Could not open the clipboard. Try again.", "クリップボードを開けませんでした。もう一度お試しください。", "No se pudo abrir el portapapeles. Probá de nuevo."],  // stClipFail
    ["The macOS random number generator failed. No password was made.", "macOS の乱数生成器でエラーが発生しました。パスワードは生成されていません。", "Falló el generador de números aleatorios de macOS. No se generó ninguna contraseña."],  // stRngFail
    ["passwords.txt", "passwords.txt", "contraseñas.txt"],  // saveDefname
    ["File", "ファイル", "Archivo"],  // menuFile
    ["Generate", "生成", "Generar"],  // menuGenerate
    ["Copy selected", "選択をコピー", "Copiar la seleccionada"],  // menuCopy
    ["Copy all", "すべてコピー", "Copiar todas"],  // menuCopyall
    ["Save as…", "名前を付けて保存…", "Guardar como…"],  // menuSave
    ["Passwords", "パスワード", "Contraseñas"],  // menuKind
    ["Characters", "文字", "Caracteres"],  // menuModeChars
    ["Passphrase", "パスフレーズ", "Frase"],  // menuModeWords
    ["PIN", "PIN", "PIN"],  // menuModePin
    ["View", "表示", "Ver"],  // menuView
    ["Theme: follow macOS", "テーマ: macOS に合わせる", "Tema: como macOS"],  // menuThemeAuto
    ["Theme: light", "テーマ: ライト", "Tema: claro"],  // menuThemeLight
    ["Theme: dark", "テーマ: ダーク", "Tema: oscuro"],  // menuThemeDark
    ["Theme and colour…", "テーマと色…", "Tema y color…"],  // menuThemedlg
    ["Theme and colour", "テーマと色", "Tema y color"],  // themeTitle
    ["Appearance", "外観", "Apariencia"],  // themeAppearance
    ["As macOS", "macOS に合わせる", "Como macOS"],  // themeAuto
    ["Light", "ライト", "Claro"],  // themeLight
    ["Dark", "ダーク", "Oscuro"],  // themeDark
    ["Colour of the window and the icon", "ウィンドウとアイコンの色", "Color de la ventana y del ícono"],  // themeColour
    ["Blue", "青", "Azul"],  // accentBlue
    ["Gold", "金", "Dorado"],  // accentGold
    ["Purple", "紫", "Morado"],  // accentPurple
    ["Sky", "空色", "Celeste"],  // accentSky
    ["Ember", "オレンジ", "Naranja"],  // accentEmber
    ["Red", "赤", "Rojo"],  // accentRed
    ["Yellow", "黄", "Amarillo"],  // accentYellow
    ["Green", "緑", "Verde"],  // accentGreen
    ["Teal", "青緑", "Verde azulado"],  // accentTeal
    ["Pink", "ピンク", "Rosa"],  // accentPink
    ["Black", "黒", "Negro"],  // accentBlack
    ["White", "白", "Blanco"],  // accentWhite
    ["Language", "言語", "Idioma"],  // menuLang
    ["English", "English", "English"],  // menuEn
    ["日本語", "日本語", "日本語"],  // menuJp
    ["Español", "Español", "Español"],  // menuEs
    ["Help", "ヘルプ", "Ayuda"],  // menuHelp
    ["Help", "ヘルプ", "Ayuda"],  // menuHelptopics
    ["About", "バージョン情報", "Acerca de"],  // menuAbout
    ["Wyrmhold — Help", "Wyrmhold — ヘルプ", "Wyrmhold — Ayuda"],  // helpTitle
    ["# What it does\nMakes strong random passwords, passphrases and PINs — for a zip, 7z or rar file sent by email, a new account, a Wi-Fi network or a lock. Nothing is stored or sent anywhere.\n# How to use it\n• Choose the kind at the top: Characters, Passphrase or PIN (⌘1, ⌘2, ⌘3).\n• Or pick a ready-made profile from the Profile button (or the Passwords menu).\n• Adjust the settings: every change makes a new set at once. Generate (⌘R) makes another.\n• To copy one password: click the copy icon at the end of its row, double-click the row, or select it and press Return or ⌘C. ⇧⌘C copies them all; ⌘S saves them to a text file.\n# When a site refuses some characters\n• It refuses symbols: choose the profile \"No symbols\", or switch off the #$% chip.\n• It accepts only some symbols: choose Symbols → Minimal (- _ .), or My own and type exactly the symbols the site lists.\n• It refuses particular characters: type them in \"Leave out\".\n• It has a maximum length: lower the length, or choose the profile \"Short\" (12). Make up for a short password with every kind of character.\n• It wants the first character to be a letter, or no repeated characters: switch on \"Start with a letter\" or \"No repeats in a row\".\n# Which kind to choose\n• Characters: the strongest for its length. Best when the password is pasted, not typed.\n• Passphrase: random words such as Copper-Showroom-Wrecking7-Salute. Longer, but far easier to remember, dictate or type on a phone. Six words give about 80 bits.\n• PIN: digits only. Safe only where wrong tries are limited, as on cards, phones and locks.\n# How the passwords are made\nEvery character or word comes from the macOS cryptographic random number generator (arc4random_buf, fed by the kernel). When a password breaks one of the rules — a kind of character missing, a repeated neighbour, a run like 123 — it is thrown away and drawn again, never patched. So every password that follows the rules is exactly as likely as any other, and no position, kind or pattern is favoured.\n# Strength\nThe entropy is counted exactly: the number of different passwords the settings can give, every rule included (n bits = 2^n possibilities). Below 50 bits is weak, 64 fair, 80 or more very strong. The guessing time assumes an attacker who has the file and tries 100 billion passwords a second. The defaults (20 characters) give about 122 bits.\n# Colours\nIn the list, digits are blue and symbols amber, so a password is easier to read back or dictate. What is copied is plain text. View → Theme and colour… chooses the theme (light, dark or as macOS) and one of twelve colours, which also colour the icon; black is the default.\n# Clipboard\nWith \"Clear clipboard after 30 s\" on, a copied password is wiped 30 seconds later, or when the program is closed, unless something else was copied in between. Copies are always marked as confidential, so clipboard managers leave them out, and they never reach your other devices through Universal Clipboard.\n# Settings\nThey are kept in the app's preferences (~/Library/Preferences/io.github.gabriel-castiglia.wyrmhold.plist). The passwords never are.\n# Good practice\nSend the password through a different channel from the file: the file by email, the password in a separate message, a chat or a call. Once the window is closed, the passwords are gone.", "# できること\n強力なランダムパスワード、パスフレーズ、PIN を作ります。メールで送る zip・7z・rar ファイル、新しいアカウント、Wi-Fi、錠前などに使えます。何も保存されず、どこにも送信されません。\n# 使い方\n• 上部で種類を選びます: 文字、パスフレーズ、PIN (⌘1、⌘2、⌘3)。\n• または「プロファイル」ボタン(または「パスワード」メニュー)から用意された設定を選びます。\n• 設定を変えると、そのたびに新しいパスワードが作られます。「生成」(⌘R) でさらに作れます。\n• 1つをコピーするには、行の右端のコピーアイコンをクリック、行をダブルクリック、または選択して return か ⌘C を押します。⇧⌘C ですべてコピー、⌘S でテキストファイルに保存します。\n# サイトが一部の文字を受け付けない場合\n• 記号を受け付けない: プロファイル「記号なし」を選ぶか、#$% をオフにします。\n• 一部の記号しか使えない: 記号 → 最小限 (- _ .) を選ぶか、「自分で指定」でサイトが示す記号だけを入力します。\n• 特定の文字を受け付けない: その文字を「除外」に入力します。\n• 最大文字数がある: 文字数を下げるか、プロファイル「短め」(12文字) を選びます。短い場合はすべての種類の文字を使って補ってください。\n• 先頭を英字に、または同じ文字の連続を禁止している: 「英字で始める」「同じ文字を連続させない」をオンにします。\n# どの種類を選ぶか\n• 文字: 長さあたり最も強力です。入力せず貼り付けて使う場合に最適です。\n• パスフレーズ: Copper-Showroom-Wrecking7-Salute のようなランダムな単語。長くなりますが、覚えたり、読み上げたり、スマホで入力したりするのがずっと楽です。6単語で約80ビットです。\n• PIN: 数字のみ。カード、スマホ、錠前のように誤入力の回数が制限される場合にだけ安全です。\n# パスワードの作り方\nすべての文字や単語は macOS の暗号用乱数生成器 (arc4random_buf、カーネルが供給) から取ります。規則に合わないパスワード(必要な種類がない、同じ文字の連続、123 のような連番など)は修正せず、捨ててもう一度引き直します。そのため、規則を満たすどのパスワードもまったく同じ確率で出て、特定の位置、種類、パターンが偏ることはありません。\n# 強度\nエントロピーは、設定で作れるパスワードの数をすべての規則を含めて正確に数えたものです(n ビット = 2^n 通り)。50ビット未満は弱く、64ビットで普通、80ビット以上で非常に強力です。推測時間は、ファイルを入手した攻撃者が毎秒1000億回試す場合の目安です。初期設定(20文字)で約122ビットです。\n# 色\n一覧では数字が青、記号がオレンジで表示されるので、読み返しや読み上げが楽になります。コピーされるのは普通のテキストです。「表示」→「テーマと色…」でテーマ(ライト、ダーク、macOS に合わせる)と12 色から色を選べます。アイコンの色も変わります(既定は黒)。\n# クリップボード\n「30秒後にクリップボードを消去」がオンのとき、コピーしたパスワードは30秒後、またはプログラムを閉じたときに消去されます(その間にほかのものをコピーした場合を除く)。コピーには常に機密の印が付くので、クリップボード管理アプリには記録されず、ユニバーサルクリップボードでほかのデバイスに送られることもありません。\n# 設定\n設定は ~/Library/Preferences/io.github.gabriel-castiglia.wyrmhold.plist に保存されます。パスワードは保存されません。\n# 安全な使い方\nパスワードはファイルとは別の方法で伝えてください。ファイルはメールで、パスワードは別のメール、チャット、電話で。ウィンドウを閉じると、パスワードは残りません。", "# Qué hace\nGenera contraseñas, frases de contraseña y PIN fuertes y al azar: para un zip, 7z o rar que se manda por email, una cuenta nueva, una red Wi-Fi o una cerradura. No guarda ni envía nada.\n# Cómo se usa\n• Elegí el tipo arriba: Caracteres, Frase o PIN (⌘1, ⌘2, ⌘3).\n• O elegí un perfil listo con el botón Perfil (o el menú Contraseñas).\n• Ajustá las opciones: cada cambio genera un juego nuevo al instante. Generar (⌘R) hace otro.\n• Para copiar una: clic en el ícono de copiar al final de su fila, doble clic en la fila, o seleccionala y apretá Intro o ⌘C. ⇧⌘C copia todas; ⌘S las guarda en un archivo de texto.\n# Cuando un sitio no acepta algunos caracteres\n• No acepta símbolos: elegí el perfil «Sin símbolos», o apagá el botón #$%.\n• Acepta solo algunos símbolos: elegí Símbolos → Mínimos (- _ .), o «Los míos» y escribí exactamente los que lista el sitio.\n• Rechaza caracteres puntuales: escribilos en «Excluir».\n• Tiene un largo máximo: bajá el largo, o elegí el perfil «Corta» (12). Compensá una contraseña corta usando todos los tipos de carácter.\n• Exige empezar con letra, o no repetir caracteres seguidos: encendé «Empezar con letra» o «Sin repetir seguidos».\n# Qué tipo elegir\n• Caracteres: lo más fuerte para su largo. Ideal cuando la contraseña se pega, no se tipea.\n• Frase: palabras al azar como Copper-Showroom-Wrecking7-Salute. Más larga, pero mucho más fácil de recordar, dictar o tipear en un teléfono. Seis palabras dan unos 80 bits.\n• PIN: solo dígitos. Seguro solo donde los intentos fallidos están limitados, como en tarjetas, teléfonos y cerraduras.\n# Cómo se hacen las contraseñas\nCada carácter o palabra sale del generador criptográfico de números aleatorios de macOS (arc4random_buf, alimentado por el núcleo). Cuando una contraseña no cumple alguna regla — falta un tipo de carácter, un carácter repetido seguido, una seguidilla como 123 — se descarta y se sortea de nuevo, nunca se parcha. Así, cualquier contraseña que cumpla las reglas es exactamente igual de probable que otra, y ninguna posición, tipo o patrón sale favorecido.\n# Fuerza\nLa entropía se cuenta exactamente: cuántas contraseñas distintas pueden salir con la configuración, con todas las reglas (n bits = 2^n posibilidades). Menos de 50 bits es débil, 64 aceptable, 80 o más muy fuerte. El tiempo para adivinarla supone un atacante que tiene el archivo y prueba 100 mil millones de contraseñas por segundo. Con lo predeterminado (20 caracteres) son unos 122 bits.\n# Colores\nEn la lista, los dígitos van en azul y los símbolos en ámbar, para releer o dictar más fácil. Lo que se copia es texto común. En Ver → Tema y color… elegís el tema (claro, oscuro o como macOS) y uno de doce colores, que también pinta el ícono; el negro es el de fábrica.\n# Portapapeles\nCon «Borrar portapapeles a los 30 s» encendido, una contraseña copiada se borra 30 segundos después, o al cerrar el programa, salvo que se haya copiado otra cosa mientras tanto. Las copias siempre van marcadas como confidenciales, así que los gestores de portapapeles no las guardan, y nunca pasan a tus otros dispositivos por el Portapapeles Universal.\n# Configuración\nSe guarda en las preferencias de la app (~/Library/Preferences/io.github.gabriel-castiglia.wyrmhold.plist). Las contraseñas, nunca.\n# Buenas prácticas\nMandá la contraseña por un canal distinto del archivo: el archivo por email y la contraseña en otro mensaje, un chat o una llamada. Al cerrar la ventana, las contraseñas desaparecen."],  // helpBody
    ["OK", "OK", "Aceptar"],  // btnOk
    ["About", "バージョン情報", "Acerca de"],  // aboutTitle
    ["Wyrmhold", "Wyrmhold", "Wyrmhold"],  // aboutName
    ["“Wyrm” is Old English for dragon and “hold” a stronghold: a wyrmhold is the dragon's keep, where a dragon guards its hoard — as this program guards your passwords.", "「Wyrm」 は古英語で「竜」、「hold」 は「砦」。Wyrmhold は竜が宝を守る砦のこと — このプログラムがあなたのパスワードを守るように。", "«Wyrm» es «dragón» en inglés antiguo y «hold», «fortaleza»: un wyrmhold es el bastión donde un dragón custodia su tesoro — como este programa custodia tus contraseñas."],  // aboutMeaning
    ["Version %@  ·  %@", "バージョン %@  ·  %@", "Versión %@  ·  %@"],  // aboutVersion
    ["Makes strong random passwords, passphrases and PINs with the macOS cryptographic random number generator, uniformly over every password that follows the chosen rules. Nothing is stored or sent anywhere: the passwords exist only in this window until you copy or save them.", "macOS の暗号用乱数生成器を使い、選んだ規則を満たすすべてのパスワードの中から均等に、強力なパスワード、パスフレーズ、PIN を作ります。何も保存されず、どこにも送信されません。パスワードは、コピーまたは保存するまでこのウィンドウの中にだけ存在します。", "Genera contraseñas, frases y PIN fuertes con el generador criptográfico de números aleatorios de macOS, de manera uniforme entre todas las contraseñas que cumplen las reglas elegidas. No guarda ni envía nada: las contraseñas existen solo en esta ventana hasta que las copiás o guardás."],  // aboutBody
    ["Author: %@", "作成者: %@", "Autor: %@"],  // aboutAuthor
    ["Passphrase words: the EFF large word list, by the Electronic Frontier Foundation, under CC BY 3.0 US (eff.org/dice). Icon: the winged dragon of Athanasius Kircher, Mundus Subterraneus (1665), public domain.", "パスフレーズの単語: Electronic Frontier Foundation の EFF large word list(CC BY 3.0 US、eff.org/dice)。アイコン: アタナシウス・キルヒャー『地下世界』(1665 年)の翼のある竜(パブリックドメイン)。", "Palabras de las frases: la lista grande de EFF, de la Electronic Frontier Foundation, bajo CC BY 3.0 US (eff.org/dice). Ícono: el dragón alado de Athanasius Kircher, Mundus Subterraneus (1665), de dominio público."],  // aboutCredits
    ["Free software under the GNU General Public License, version 2 (GPL-2.0-only). It comes with no warranty. © 2026 Gabriel Castiglia.", "GNU 一般公衆利用許諾書 第2版 (GPL-2.0-only) のもとで配布されるフリーソフトウェアです。無保証です。© 2026 Gabriel Castiglia", "Software libre bajo la Licencia Pública General de GNU, versión 2 (GPL-2.0-only). Se ofrece sin garantía. © 2026 Gabriel Castiglia."],  // aboutLicense
]
