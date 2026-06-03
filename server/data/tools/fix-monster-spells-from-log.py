#!/usr/bin/env python3
"""
Comenta <attack>/<defense> com spell custom inexistente (log: Unknown spell name).
Substituicoes simples podem ser aplicadas via --substitute.

Uso:
  python fix-monster-spells-from-log.py --dry-run
  python fix-monster-spells-from-log.py
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
LOG = BASE / "logs/tfs/erroconsole.log"
MONSTER_ROOT = BASE / "monster"
TAG = "SPELL_860"

SPELL_ERR = re.compile(
    r'\[Error - Monsters::deserializeSpell\] - .+ - Unknown spell name: (.+)'
)
CANT_SPELL = re.compile(r"Cant load spell\. data/monster/(.+?\.xml)")

# spell custom -> attack name nativo TFS (attrs extras opcionais no XML manual)
SUBSTITUTIONS: dict[str, str] = {
    "practise fire wave": "fire",  # usar length/spread no XML
    "front sweep": "physical",
}

ATTACK_OPEN = re.compile(r'^(\s*)<attack\s+name="([^"]+)"([^>]*)>\s*$', re.I)
ATTACK_SELF = re.compile(r'^(\s*)<attack\s+name="([^"]+)"([^>]*)/>\s*$', re.I)
DEFENSE_SELF = re.compile(r'^(\s*)<defense\s+name="([^"]+)"([^>]*)/>\s*$', re.I)
FLAG_PET = re.compile(r'^(\s*)<flag\s+pet="1"\s*/>\s*$', re.I)


def parse_log(text: str) -> tuple[set[str], set[str]]:
    files: set[str] = set()
    spells: set[str] = set()
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = SPELL_ERR.search(line)
        if m:
            spells.add(m.group(1).lower())
        if i + 1 < len(lines):
            nxt = CANT_SPELL.search(lines[i + 1])
            if nxt and SPELL_ERR.search(line):
                files.add(nxt.group(1).replace("\\", "/"))
        m2 = CANT_SPELL.search(line)
        if m2:
            files.add(m2.group(1).replace("\\", "/"))
    return files, spells


def comment_block(lines: list[str], start: int, end: int, spell: str) -> list[str]:
    indent = re.match(r'^(\s*)', lines[start]).group(1)
    out = [f'{indent}<!-- {TAG}: {spell} -->\n']
    for i in range(start, end + 1):
        out.append(indent + "<!-- " + lines[i].lstrip() + " -->\n")
    return out


def fix_file(path: Path, bad_spells: set[str], dry_run: bool) -> int:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    out: list[str] = []
    changed = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        m_self = ATTACK_SELF.match(line) or DEFENSE_SELF.match(line)
        if m_self:
            name = m_self.group(2)
            if name.lower() in bad_spells:
                if not dry_run:
                    out.append(f'{m_self.group(1)}<!-- {TAG}: {name} -->\n')
                    out.append(f"{m_self.group(1)}<!-- {line.strip()} -->\n")
                else:
                    out.append(line + "\n")
                changed += 1
                i += 1
                continue
        m_open = ATTACK_OPEN.match(line)
        if m_open and m_open.group(2).lower() in bad_spells:
            end = i
            while end < len(lines) and "</attack>" not in lines[end]:
                end += 1
            if end < len(lines):
                if not dry_run:
                    out.extend(comment_block(lines, i, end, m_open.group(2)))
                changed += 1
                i = end + 1
                continue
        if FLAG_PET.match(line):
            if not dry_run:
                out.append(
                    f'{FLAG_PET.match(line).group(1)}'
                    f"<!-- flag pet removido ({TAG}) -->\n"
                )
            changed += 1
            i += 1
            continue
        out.append(line + "\n")
        i += 1

    if changed and not dry_run:
        path.write_text("".join(out), encoding="utf-8", newline="\n")
    return changed


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    text = LOG.read_text(encoding="utf-8", errors="replace")
    files, spells = parse_log(text)
    print(f"Spells no log: {sorted(spells)}")
    print(f"Arquivos: {len(files)}")
    total = 0
    for rel in sorted(files):
        p = MONSTER_ROOT / Path(rel)
        if not p.is_file():
            print(f"[skip] {rel}")
            continue
        n = fix_file(p, spells, args.dry_run)
        if n:
            print(f"{'[dry-run] ' if args.dry_run else ''}{rel}: {n}")
            total += n
    print(f"Total: {total}")


if __name__ == "__main__":
    main()
