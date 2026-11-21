#!/bin/zsh
# compilar.sh: builds Forja and produces a signed build/Forja.app.
#
# Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
# Date: November 10, 2026
# SPDX-License-Identifier: GPL-2.0-only
#
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License, version 2, as published by the Free Software Foundation.
# It is distributed WITHOUT ANY WARRANTY. See the LICENSE file for details.
#
# Requires Apple's Command Line Tools (xcode-select --install); Xcode is not needed.
# The version is written here and nowhere else.

set -euo pipefail
RAIZ="${0:A:h:h}"
cd "$RAIZ"

# Spotlight must not list the copies built here (21-nov-2026: Citadel and Vigía showed twice, and old Gryphmark
# copies from expanded packages): build is a link to build.noindex, a folder Spotlight leaves out.
if [[ ! -L build ]]; then
    mkdir -p build.noindex
    if [[ -d build ]]; then rsync -a build/ build.noindex/ && rm -rf build; fi
    ln -s build.noindex build
fi
[[ "${FIRMA:-}" == adhoc ]] || source scripts/firma.sh

VERSION="3.0.0"
COMPILACION="1"
FECHA="2026-11-10"
APP="build/Forja.app"
OBJ="build/obj"

rm -rf "$APP" "$OBJ"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OBJ"

# 1. The C engine (the same as the Windows version, with the macOS random number generator)
clang -std=c11 -O2 -Wall -Wextra -Werror -target arm64-apple-macos15.0 \
    -c Sources/Engine/pwgen.c -o "$OBJ/pwgen.o"

# 2. The app
swiftc -O -swift-version 5 -target arm64-apple-macos15.0 -module-name Forja \
    -import-objc-header Sources/Engine/bridge.h \
    Sources/*.swift "$OBJ/pwgen.o" \
    -o "$APP/Contents/MacOS/Forja"
rm -rf "$OBJ"

# 3. Icon: every size macOS expects, from the 1024 px PNG; and the layer the app tints
SET="$(mktemp -d)/Forja.iconset"
mkdir -p "$SET"
for t in 16 32 128 256 512; do
    sips -z $t $t icono/icono-1024.png --out "$SET/icon_${t}x${t}.png" >/dev/null
    sips -z $((t * 2)) $((t * 2)) icono/icono-1024.png --out "$SET/icon_${t}x${t}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o "$APP/Contents/Resources/Forja.icns"
rm -rf "${SET:h}"
cp assets/icon_layer.wyi "$APP/Contents/Resources/"
mkdir -p "$APP/Contents/Resources/licenses"
cp LICENSE "$APP/Contents/Resources/licenses/Forja-LICENSE"

# 4. Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Forja</string>
    <key>CFBundleDisplayName</key><string>Forja</string>
    <key>CFBundleIdentifier</key><string>io.github.gabriel-castiglia.forja</string>
    <key>CFBundleExecutable</key><string>Forja</string>
    <key>CFBundleIconFile</key><string>Forja</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$COMPILACION</string>
    <key>ForjaDate</key><string>$FECHA</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>ja</string><string>es</string></array>
    <key>NSHumanReadableCopyright</key><string>© 2026 Gabriel Castiglia · GPL-2.0-only</string>
    <key>LSMinimumSystemVersion</key><string>15.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# 5. Sign with the stable identity (see scripts/firma.sh). FIRMA=adhoc signs without it, for a
#    quick local test: macOS then asks again for any permission on every build.
if [[ "${FIRMA:-}" == adhoc ]]; then
    codesign --force --sign - --timestamp=none "$APP"
else
    preparar_firma
    codesign --force --sign "$IDENTIDAD" --keychain "$LLAVERO" --timestamp=none "$APP"
fi

echo "Built: $RAIZ/$APP (version $VERSION)"
