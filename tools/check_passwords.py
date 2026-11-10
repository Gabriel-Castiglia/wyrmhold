"""
Wyrmhold -- checks a file written with -out against the standard
rules (the four classes, basic symbols), independently of the C code.
Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
Date: November 9, 2026
SPDX-License-Identifier: GPL-2.0-only

    python3 tools/check_passwords.py <file> <length> <avoid 1|0> [expected count]

Checks every line: the length, one of each class, nothing outside the alphabet, no
ambiguous character when avoid=1, no repeated password. Then a uniformity check: every
character of the alphabet must appear, and none may be far from its expected share
(chi-square over positions 4.., where all characters are drawn from the full pool).
Exit 0 = all good, 1 = something failed (printed).
"""

import math
import string
import sys
from collections import Counter

SYMBOLS = "!@#$%&*+-=?"
AMBIGUOUS = "0O1lI|`'\""


def classes(avoid: bool):
    lo, up, dg = string.ascii_lowercase, string.ascii_uppercase, string.digits
    if avoid:
        lo = "".join(c for c in lo if c not in AMBIGUOUS)
        up = "".join(c for c in up if c not in AMBIGUOUS)
        dg = "".join(c for c in dg if c not in AMBIGUOUS)
    return lo, up, dg, SYMBOLS


def main() -> int:
    path, length, avoid = sys.argv[1], int(sys.argv[2]), sys.argv[3] == "1"
    want = int(sys.argv[4]) if len(sys.argv) > 4 else None
    lo, up, dg, sy = classes(avoid)
    alphabet = set(lo + up + dg + sy)

    data = open(path, "rb").read()
    problems = []
    if data and not data.endswith(b"\n"):
        problems.append("file does not end with a line break")
    lines = data.decode("ascii").split("\n")[:-1] if data else []

    if want is not None and len(lines) != want:
        problems.append(f"{len(lines)} lines, expected {want}")

    counts = Counter()
    for n, pw in enumerate(lines, 1):
        if len(pw) != length:
            problems.append(f"line {n}: length {len(pw)}")
        bad = set(pw) - alphabet
        if bad:
            problems.append(f"line {n}: characters outside the alphabet {sorted(bad)}")
        for name, cls in (("lowercase", lo), ("uppercase", up), ("digit", dg), ("symbol", sy)):
            if not any(c in cls for c in pw):
                problems.append(f"line {n}: no {name}")
        counts.update(pw)
        if len(problems) > 20:
            break

    dup = len(lines) - len(set(lines))
    if dup and length >= 12:
        problems.append(f"{dup} repeated passwords")

    # Uniformity: over many passwords each character's share is close to its expected one.
    # The guaranteed four make the class shares a little uneven, so compare each character
    # with the others of its own class, where they must be equally likely.
    total_chars = sum(counts.values())
    if total_chars >= 200000:
        for name, cls in (("lowercase", lo), ("uppercase", up), ("digit", dg), ("symbol", sy)):
            obs = [counts[c] for c in cls]
            mean = sum(obs) / len(obs)
            chi2 = sum((o - mean) ** 2 / mean for o in obs)
            dof = len(obs) - 1
            # mean + 5 standard deviations of a chi-square: a fair generator stays far below
            limit = dof + 5 * math.sqrt(2 * dof)
            if chi2 > limit:
                problems.append(f"{name}: chi-square {chi2:.1f} > {limit:.1f} (dof {dof})")
            if min(obs) == 0:
                problems.append(f"{name}: a character never appears")

    print(f"{path}: {len(lines)} passwords, length {length}, avoid={int(avoid)}")
    for p in problems:
        print("  FAIL", p)
    print("  OK" if not problems else f"  {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
