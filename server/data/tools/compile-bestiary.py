import os
import xml.etree.ElementTree as ET
import json

# Paths
SERVER_DIR = r"C:\8.6\otserv_860\otc-server\server"
CLIENT_DIR = r"C:\8.6\otserv_860\otc-server\client"

MONSTERS_XML_PATH = os.path.join(SERVER_DIR, "data", "monster", "monsters.xml")
CLIENT_DB_PATH = os.path.join(CLIENT_DIR, "modules", "game_bestiary", "bestiary_database.json")
SERVER_LUA_PATH = os.path.join(SERVER_DIR, "data", "lib", "bestiary_monsters.lua")

def load_existing_db():
    if not os.path.exists(CLIENT_DB_PATH):
        return {}
    try:
        with open(CLIENT_DB_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return {item['name'].lower(): item for item in data}
    except Exception as e:
        print(f"Warning: could not load existing database: {e}")
        return {}

def get_difficulty(exp, name_lower, existing_map):
    # Try existing map first to preserve manual edits
    if name_lower in existing_map:
        return existing_map[name_lower].get('difficulty', 1)
    
    # Otherwise fallback to default formula
    if exp < 150:
        return 1  # Inofensivo
    elif exp < 1500:
        return 2  # Fácil
    elif exp < 5000:
        return 3  # Médio
    else:
        return 4  # Difícil

def main():
    if not os.path.exists(MONSTERS_XML_PATH):
        print(f"Error: monsters.xml not found at {MONSTERS_XML_PATH}")
        return

    print("Loading existing bestiary database for backup mapping...")
    existing_map = load_existing_db()

    print("Parsing monsters.xml...")
    try:
        tree = ET.parse(MONSTERS_XML_PATH)
        root = tree.getroot()
    except Exception as e:
        print(f"Error parsing monsters.xml: {e}")
        return

    monster_names = []
    database_entries = []

    for monster_node in root.findall("monster"):
        name = monster_node.attrib.get("name")
        file_rel = monster_node.attrib.get("file")
        if not name or not file_rel:
            continue

        file_path = os.path.join(SERVER_DIR, "data", "monster", file_rel)
        if not os.path.exists(file_path):
            print(f"Warning: Monster file not found for {name} ({file_rel})")
            continue

        try:
            m_tree = ET.parse(file_path)
            m_root = m_tree.getroot()
        except Exception as e:
            print(f"Warning: Error parsing XML for {name}: {e}")
            continue

        # Extract details
        name_canonical = m_root.attrib.get("name", name)
        race_attr = m_root.attrib.get("race")
        if not race_attr:
            print(f"Warning: Monster '{name_canonical}' in {file_rel} is missing the 'race' attribute. Adding race='blood'...")
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
            except UnicodeDecodeError:
                with open(file_path, "r", encoding="iso-8859-1") as f:
                    content = f.read()

            import re
            pattern = re.compile(r'(<monster\b[^>]*>)', re.IGNORECASE)
            match = pattern.search(content)
            if match:
                tag = match.group(1)
                if 'race=' not in tag.lower():
                    # Case insensitive tag correction
                    new_tag = tag.replace('<monster', '<monster race="blood"', 1)
                    new_tag = tag.replace('<Monster', '<Monster race="blood"', 1)
                    content = content.replace(tag, new_tag, 1)

                    try:
                        with open(file_path, "w", encoding="utf-8") as f:
                            f.write(content)
                    except:
                        with open(file_path, "w", encoding="iso-8859-1") as f:
                            f.write(content)
                    print(f"Successfully added race='blood' to {file_path}")

            # Re-parse
            try:
                m_tree = ET.parse(file_path)
                m_root = m_tree.getroot()
                race_attr = m_root.attrib.get("race", "blood")
            except Exception as e:
                print(f"Error re-parsing XML for {name}: {e}")
                race_attr = "blood"

        group = race_attr.capitalize() # Capitalize "blood" to "Blood" for cleaner UI group names

        try:
            exp = int(m_root.attrib.get("experience", 0))
        except:
            exp = 0

        # Health
        hp = 100
        health_node = m_root.find("health")
        if health_node is not None:
            try:
                hp = int(health_node.attrib.get("max", 100))
            except:
                pass

        # Look/Outfit
        look_id = 0
        look_type_ex = 0
        look_node = m_root.find("look")
        if look_node is not None:
            try:
                look_id = int(look_node.attrib.get("type", 0))
                look_type_ex = int(look_node.attrib.get("typeex", 0))
            except:
                pass

        # Weaknesses/Elements
        weakness = []
        elements_node = m_root.find("elements")
        if elements_node is not None:
            for element_node in elements_node.findall("element"):
                for key, val in element_node.attrib.items():
                    if key.endswith("Percent"):
                        element_name = key[:-7] # e.g. physicalPercent -> physical
                        try:
                            percent = int(val)
                            # In bestiary_database.json, val represents percent damage taken (100 = neutral, 110 = weak, 90 = resistant)
                            # In TFS XML, elementPercent = 10 means 10% resistance, i.e. 90% damage taken.
                            # So val = 100 - percent
                            weakness.append({
                                "element": element_name,
                                "val": 100 - percent
                            })
                        except:
                            pass

        # Loot
        loot = []
        loot_node = m_root.find("loot")
        if loot_node is not None:
            for item_node in loot_node.findall("item"):
                item_id = item_node.attrib.get("id")
                item_name = item_node.attrib.get("name")
                chance_str = item_node.attrib.get("chance")
                count_str = item_node.attrib.get("countmax")

                if not item_id and not item_name:
                    continue

                try:
                    chance = int(chance_str) if chance_str else 1000
                except:
                    chance = 1000

                try:
                    countmax = int(count_str) if count_str else 1
                except:
                    countmax = 1

                loot_entry = {
                    "chance": chance,
                    "countmax": countmax
                }

                if item_id:
                    try:
                        loot_entry["id"] = int(item_id)
                    except:
                        pass
                if item_name:
                    loot_entry["name"] = item_name

                loot.append(loot_entry)

        # Build entry
        difficulty = get_difficulty(exp, name_canonical.lower(), existing_map)

        entry = {
            "name": name_canonical,
            "group": group,
            "difficulty": difficulty,
            "hp": hp,
            "exp": exp,
            "lookId": look_id,
            "kills": 0,
            "weakness": weakness,
            "loot": loot
        }

        # Handle typeex for outfits if present
        if look_type_ex > 0:
            entry["lookTypeEx"] = look_type_ex

        database_entries.append(entry)
        monster_names.append(name_canonical)

    # Output Client Database
    print(f"Writing {len(database_entries)} entries to client database at {CLIENT_DB_PATH}...")
    try:
        with open(CLIENT_DB_PATH, 'w', encoding='utf-8') as f:
            json.dump(database_entries, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"Error writing client database: {e}")
        return

    # Map difficulty to kills based on client BestiaryDifficulty table
    difficulty_to_kills = {
        1: 25,
        2: 500,
        3: 1000,
        4: 2500
    }

    # Map difficulty to points based on client BestiaryDifficulty table
    difficulty_to_points = {
        1: 1,
        2: 15,
        3: 25,
        4: 50
    }

    # Output Server Lua Names List
    print(f"Writing {len(monster_names)} names to server lua file at {SERVER_LUA_PATH}...")
    try:
        with open(SERVER_LUA_PATH, 'w', encoding='utf-8') as f:
            f.write("-- Arquivo gerado automaticamente pelo compilador de bestiario. Nao modifique manualmente!\n")
            f.write("BestiaryMonsterNames = {\n")
            for name in sorted(monster_names):
                f.write(f'  "{name}",\n')
            f.write("}\n\n")
            
            f.write("BestiaryMonsterLimits = {\n")
            for entry in database_entries:
                limit = difficulty_to_kills.get(entry["difficulty"], 500)
                safe_name = entry["name"].replace('"', '\\"')
                f.write(f'  ["{safe_name}"] = {limit},\n')
            f.write("}\n\n")
            
            f.write("BestiaryMonsterPoints = {\n")
            for entry in database_entries:
                pts = difficulty_to_points.get(entry["difficulty"], 15)
                safe_name = entry["name"].replace('"', '\\"')
                f.write(f'  ["{safe_name}"] = {pts},\n')
            f.write("}\n\n")

            f.write("BestiaryMonsterExp = {\n")
            for entry in database_entries:
                base_exp = entry.get("exp", 0)
                safe_name = entry["name"].replace('"', '\\"')
                f.write(f'  ["{safe_name}"] = {base_exp},\n')
            f.write("}\n")
    except Exception as e:
        print(f"Error writing server lua file: {e}")
        return

    print("Success! Bestiary compiled successfully.")

if __name__ == "__main__":
    main()
