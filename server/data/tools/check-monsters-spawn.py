#!/usr/bin/env python3
"""Cruza monstros citados em erroconsole.log com arquivos *spawn*.xml e raids."""
import re
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]  # server/data
LOG = BASE / "logs/tfs/erroconsole.log"
MONSTER_DIR = BASE / "monster"

def extract_xml_paths(log_text: str) -> list[str]:
    # paths podem ter espacos: "update 12.30/brain head.xml"
    return sorted(set(re.findall(r"data/monster/(.+?\.xml)", log_text)))

def monster_name(xml_path: Path) -> str | None:
    if not xml_path.is_file():
        return None
    m = re.search(r'<monster\s+name="([^"]+)"', xml_path.read_text(encoding="utf-8", errors="replace"))
    return m.group(1) if m else None

def main():
    log_text = LOG.read_text(encoding="utf-8", errors="replace")
    rel_paths = extract_xml_paths(log_text)

    spawn_files = list((BASE / "world").rglob("*spawn*.xml"))
    spawn_files += list((BASE / "raids").rglob("*.xml")) if (BASE / "raids").exists() else []
    spawn_text = {f.name: f.read_text(encoding="utf-8", errors="replace") for f in spawn_files}

    in_spawn, not_spawn, missing = [], [], []

    for rel in rel_paths:
        full = MONSTER_DIR / rel.replace("/", "\\").replace("\\", "/")
        # Path handles mixed separators
        full = MONSTER_DIR.joinpath(*rel.split("/"))
        name = monster_name(full)
        if not name:
            missing.append(rel)
            continue
        found = [sf for sf, txt in spawn_text.items() if f'name="{name}"' in txt]
        entry = (name, rel, found)
        if found:
            in_spawn.append(entry)
        else:
            not_spawn.append(entry)

    print(f"Arquivos no log: {len(rel_paths)}")
    print(f"  Com spawn: {len(in_spawn)}")
    print(f"  Sem spawn: {len(not_spawn)}")
    print(f"  XML ausente/sem name: {len(missing)}")
    print()
    print("=== SEM SPAWN (candidatos a remover da pasta monster) ===")
    for name, rel, _ in sorted(not_spawn, key=lambda x: x[0].lower()):
        print(f"  {name:40}  {rel}")
    print()
    print("=== COM SPAWN (manter; corrigir loot/spell se necessario) ===")
    for name, rel, files in sorted(in_spawn, key=lambda x: x[0].lower()):
        print(f"  {name:40}  {rel}  -> {', '.join(files)}")

if __name__ == "__main__":
    main()
