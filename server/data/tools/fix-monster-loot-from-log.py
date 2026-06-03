#!/usr/bin/env python3
"""
Comenta linhas <item name="..."/> que geram erro no erroconsole.log
(Unknown loot / Non-unique loot). Nao altera itens por id=.

Uso:
  python fix-monster-loot-from-log.py
  python fix-monster-loot-from-log.py --dry-run
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
LOG = BASE / "logs/tfs/erroconsole.log"
MONSTER_ROOT = BASE / "monster"
TAG = "LOOT_860"

UNKNOWN_RE = re.compile(r'Unknown loot item "([^"]+)"')
NONUNIQUE_RE = re.compile(r'Non-unique loot item "([^"]+)"')
CANT_LOOT_RE = re.compile(r"Cant load loot\. data/monster/(.+?\.xml)")
ITEM_LINE_RE = re.compile(
    r'^(\s*)<item\s+([^>]*\bname="([^"]+)"[^>]*)/>(\s*(?:<!--.*?-->)?\s*)$',
    re.IGNORECASE,
)


def parse_log(log_text: str) -> tuple[set[str], set[str]]:
    """Retorna (arquivos .xml relativos, nomes de item problematicos)."""
    files: set[str] = set()
    bad_items: set[str] = set()
    lines = log_text.splitlines()

    for i, line in enumerate(lines):
        m_file = CANT_LOOT_RE.search(line)
        if m_file:
            files.add(m_file.group(1).replace("\\", "/"))

        for pat in (UNKNOWN_RE, NONUNIQUE_RE):
            m = pat.search(line)
            if m:
                bad_items.add(m.group(1).lower())

        if i + 1 < len(lines):
            nxt = CANT_LOOT_RE.search(lines[i + 1])
            if nxt and (UNKNOWN_RE.search(line) or NONUNIQUE_RE.search(line)):
                files.add(nxt.group(1).replace("\\", "/"))

    return files, bad_items


def comment_item_line(line: str, bad_lower: set[str]) -> tuple[str, bool]:
    m = ITEM_LINE_RE.match(line)
    if not m:
        return line, False
    indent, attrs, name, trail = m.group(1), m.group(2), m.group(3), m.group(4)
    if name.lower() not in bad_lower:
        return line, False
    if f"{TAG}:" in line or line.strip().startswith("<!--"):
        return line, False
    note = ""
    if trail:
        inner = re.search(r"<!--\s*(.*?)\s*-->", trail)
        if inner:
            note = f" ({inner.group(1)})"
    commented = (
        f'{indent}<!-- {TAG}: {name}{note} -->\n'
        f"{indent}<!-- <item {attrs}/> -->"
    )
    return commented, True


def fix_file(path: Path, bad_lower: set[str], dry_run: bool) -> int:
    text = path.read_text(encoding="utf-8", errors="replace")
    out_lines: list[str] = []
    changed = 0
    for line in text.splitlines(keepends=True):
        if line.endswith("\n"):
            core, nl = line[:-1], "\n"
        else:
            core, nl = line, ""
        new_core, did = comment_item_line(core, bad_lower)
        if did:
            changed += 1
            out_lines.append(new_core + nl)
        else:
            out_lines.append(line)

    if changed and not dry_run:
        path.write_text("".join(out_lines), encoding="utf-8", newline="\n")
    return changed


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--include-unused",
        action="store_true",
        help="tambem corrige monster/_unused_monsters/",
    )
    args = ap.parse_args()

    log_text = LOG.read_text(encoding="utf-8", errors="replace")
    files, bad_items = parse_log(log_text)

    print(f"Itens problematicos: {len(bad_items)}")
    for n in sorted(bad_items):
        print(f"  - {n}")
    print(f"Arquivos no log: {len(files)}")

    total = 0
    for rel in sorted(files):
        path = MONSTER_ROOT / Path(rel)
        if not path.is_file():
            print(f"[skip] nao encontrado: {rel}")
            continue
        n = fix_file(path, bad_items, args.dry_run)
        if n:
            print(f"{'[dry-run] ' if args.dry_run else ''}{rel}: {n} linha(s)")
            total += n

    if args.include_unused:
        EXTRA_BAD = {
            "giant amethyst",
            "spectral scrap of cloth",
            "small ladybug",
            "giant sapphire",
            "red silk flower",
            "srezz' eye",
            "yirkas' egg",
            "dirty cape",
            "lion axe",
            "lion hammer",
            "lion longbow",
            "lion plate",
            "lion rod",
            "lion spangenhelm",
            "lion spellbook",
            "pirate coin",
            "pirate tail",
        }
        unused = MONSTER_ROOT / "_unused_monsters"
        if unused.is_dir():
            scan_bad = bad_items | EXTRA_BAD
            for path in sorted(unused.rglob("*.xml")):
                n = fix_file(path, scan_bad, args.dry_run)
                if n:
                    rel = path.relative_to(MONSTER_ROOT).as_posix()
                    print(f"{'[dry-run] ' if args.dry_run else ''}{rel}: {n} linha(s)")
                    total += n

    print(f"\nTotal linhas comentadas: {total}")


if __name__ == "__main__":
    main()
