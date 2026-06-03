#!/usr/bin/env python3
"""
Move os 22 monstros "seguros" (sem spawn/Lua) para monster/_unused_monsters/
e remove entradas de monsters.xml + bestiary_monsters.lua.

Uso:
  python archive-unused-monsters.py          # executa
  python archive-unused-monsters.py --dry-run
  python archive-unused-monsters.py --restore  # desfaz (move de volta)
"""
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]  # server/data
MONSTER_DIR = BASE / "monster"
ARCHIVE_DIR = MONSTER_DIR / "_unused_monsters"
MONSTERS_XML = MONSTER_DIR / "monsters.xml"
BESTIARY_LUA = BASE / "lib" / "bestiary_monsters.lua"
MANIFEST = ARCHIVE_DIR / "_manifest.txt"

# rel path (dentro de monster/) -> nomes a remover de monsters.xml e bestiary
SAFE_ENTRIES: list[dict] = [
    {"rel": "12.40/bosses/ancient lion knight.xml", "names": ["Ancient Lion Knight"]},
    {"rel": "12.30/Bad Thought.xml", "names": ["Bad Thought"]},
    {"rel": "12.40/bosses/Basilisco.xml", "names": ["Basilisco"]},
    {"rel": "update 12.30/brain head.xml", "names": ["Brain Head"]},
    {"rel": "update 12.30/brother worm.xml", "names": ["Brother Worm"]},
    {"rel": "12.40/bosses/drume.xml", "names": ["Drume"]},
    {"rel": "Winter_update/izcandar_the_banished.xml", "names": ["Izcandar the Banished"]},
    {"rel": "12.40/knight.xml", "names": ["Knight's Apparition"]},
    {"rel": "12.40/Paladin's Apparition.xml", "names": ["Paladin's Apparition"]},
    {
        "rel": "12.40/Sorcerer's Apparition.xml",
        "names": ["Sorcerer's Apparition", "Druid's Apparition"],
    },
    {"rel": "12.60/Pirat Bombardier.xml", "names": ["Pirat Bombardier"]},
    {"rel": "12.60/Pirat Mate.xml", "names": ["Pirat Mate"]},
    {"rel": "12.60/Pirat Scoundrel.xml", "names": ["Pirate Scoundrel"]},
    {"rel": "12.60/Ratmiral Blackwhiskers.xml", "names": ["Ratmiral Blackwhiskers"]},
    {"rel": "12.60/Smelly Cheese.xml", "names": ["Smelly Cheese"]},
    {"rel": "12.40/bosses/srezz yellow eyes.xml", "names": ["Srezz Yellow Eyes"]},
    {"rel": "12.40/bosses/kraken.xml", "names": ["Tentugly's Head"]},
    {"rel": "update 12.30/the pale worm.xml", "names": ["The Pale Worm"]},
    {"rel": "The_percht_queens_island/the_percht_queen.xml", "names": ["The Percht Queen"]},
    {
        "rel": "11.8/the_scourge_of_oblivion.xml",
        "names": ["The Scourge of Oblivion", "The Scourge Of Oblivion"],
    },
    {"rel": "12.60/Weak Spot.xml", "names": ["Weak Spot"]},
    {"rel": "12.40/bosses/yirkas blue scales.xml", "names": ["Yirkas Blue Scales"]},
]

# lixo duplicado (nao esta em monsters.xml)
EXTRA_REL = ["12.40/bosses/.xml", "12.30/Rewar The Bloody.xml"]


def all_names() -> set[str]:
    names: set[str] = set()
    for e in SAFE_ENTRIES:
        names.update(e["names"])
    return names


def all_rels() -> set[str]:
    rels = {e["rel"] for e in SAFE_ENTRIES} | set(EXTRA_REL)
    return rels


def patch_monsters_xml(content: str, remove_names: set[str], remove_files: set[str]) -> tuple[str, int]:
    out: list[str] = []
    removed = 0
    name_re = re.compile(r'name="([^"]+)"')
    file_re = re.compile(r'file="([^"]+)"')
    for line in content.splitlines(keepends=True):
        if "<monster " not in line:
            out.append(line)
            continue
        m_name = name_re.search(line)
        m_file = file_re.search(line)
        name = m_name.group(1) if m_name else ""
        file_attr = m_file.group(1).replace("\\", "/") if m_file else ""
        if name in remove_names or file_attr in remove_files:
            removed += 1
            continue
        out.append(line)
    return "".join(out), removed


def patch_bestiary_lua(content: str, remove_names: set[str]) -> tuple[str, int]:
    out: list[str] = []
    removed = 0
    for line in content.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith('"') and stripped.endswith('",'):
            name = stripped[1:-2]
            if name in remove_names:
                removed += 1
                continue
        out.append(line)
    return "".join(out), removed


def move_to_archive(rel: str, dry_run: bool) -> bool:
    src = MONSTER_DIR.joinpath(*rel.split("/"))
    dst = ARCHIVE_DIR.joinpath(*rel.split("/"))
    if not src.is_file():
        print(f"  [skip] ausente: {rel}")
        return False
    if dry_run:
        print(f"  [dry-run] mover: {rel}")
        return True
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dst))
    print(f"  [ok] arquivado: {rel}")
    return True


def restore_from_archive(dry_run: bool) -> None:
    if not ARCHIVE_DIR.is_dir():
        print("Nada para restaurar (_unused_monsters/ nao existe).")
        return
    moved = 0
    for src in sorted(ARCHIVE_DIR.rglob("*.xml")):
        if src.name.startswith("_"):
            continue
        rel = src.relative_to(ARCHIVE_DIR).as_posix()
        dst = MONSTER_DIR.joinpath(*rel.split("/"))
        if dst.is_file():
            print(f"  [skip] ja existe: {rel}")
            continue
        if dry_run:
            print(f"  [dry-run] restaurar: {rel}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))
            print(f"  [ok] restaurado: {rel}")
        moved += 1
    print(f"Restaurados: {moved} arquivo(s)")


def run_archive(dry_run: bool) -> None:
    names = all_names()
    files = all_rels()

    print("=== Arquivando XMLs ===")
    archived = 0
    for rel in sorted(files):
        if move_to_archive(rel, dry_run):
            archived += 1

    print("\n=== monsters.xml ===")
    xml_text = MONSTERS_XML.read_text(encoding="utf-8")
    new_xml, n_xml = patch_monsters_xml(xml_text, names, files)
    print(f"  linhas removidas: {n_xml}")
    if not dry_run and n_xml:
        MONSTERS_XML.write_text(new_xml, encoding="utf-8", newline="\n")

    print("\n=== bestiary_monsters.lua ===")
    lua_text = BESTIARY_LUA.read_text(encoding="utf-8")
    new_lua, n_lua = patch_bestiary_lua(lua_text, names)
    print(f"  entradas removidas: {n_lua}")
    if not dry_run and n_lua:
        BESTIARY_LUA.write_text(new_lua, encoding="utf-8", newline="\n")

    if not dry_run:
        ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
        MANIFEST.write_text(
            "\n".join(sorted(files)) + "\n",
            encoding="utf-8",
        )
        print(f"\nManifest: {MANIFEST}")
    print(f"\nConcluido. XMLs arquivados: {archived} | dry_run={dry_run}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="apenas simula")
    parser.add_argument("--restore", action="store_true", help="move de volta para monster/")
    args = parser.parse_args()

    if args.restore:
        restore_from_archive(args.dry_run)
        if not args.dry_run:
            print(
                "\nAVISO: monsters.xml e bestiary_monsters.lua NAO foram revertidos automaticamente."
                "\nRestaure via git ou reexecute o patch manualmente."
            )
        return

    run_archive(args.dry_run)


if __name__ == "__main__":
    main()
