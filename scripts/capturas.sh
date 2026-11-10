#!/bin/zsh
# capturas.sh: draws the pictures of the manuals (docs/img) with the app itself.
#
# Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
# Date: November 10, 2026
# SPDX-License-Identifier: GPL-2.0-only
#
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License, version 2, as published by the Free Software Foundation.
# It is distributed WITHOUT ANY WARRANTY. See the LICENSE file for details.
#
# Uses build/Wyrmhold.app (scripts/compilar.sh). The screenshot mode never reads or writes the
# app's settings; the passwords in the pictures are random ones made on the spot.

set -euo pipefail
RAIZ="${0:A:h:h}"
cd "$RAIZ"
B=build/Wyrmhold.app/Contents/MacOS/Wyrmhold
[[ -x $B ]] || { echo "build the app first: scripts/compilar.sh" >&2; exit 1 }
mkdir -p docs/img
for idioma in en es ja; do
    $B --screenshot docs/img/window-$idioma.png --lang $idioma --theme light
    $B --screenshot docs/img/theme-$idioma.png --view theme --lang $idioma --theme light
done
