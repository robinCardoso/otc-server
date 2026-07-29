import os
import xml.etree.ElementTree as ET
import json
import re

SERVER_DIR = r"C:\8.6\otserv_860\otc-server\server"
CLIENT_DIR = r"C:\8.6\otserv_860\otc-server\client"

SPELLS_XML_PATH = os.path.join(SERVER_DIR, "data", "spells", "spells.xml")
SPELLS_LUA_PATH = os.path.join(CLIENT_DIR, "modules", "gamelib", "spells.lua")

VOCATION_MAP = {
    "sorcerer": 1,
    "master sorcerer": 5,
    "druid": 2,
    "elder druid": 6,
    "paladin": 3,
    "royal paladin": 7,
    "knight": 4,
    "elite knight": 8
}

GROUP_MAP = {
    "attack": 1,
    "healing": 2,
    "support": 3,
    "special": 4,
    "cripple": 5
}

def load_existing_spells_info(spells_lua_path):
    existing = {}
    if not os.path.exists(spells_lua_path):
        return existing
        
    spell_re = re.compile(r"^\s*\[['\"]([^'\"]+)['\"]\]\s*=\s*\{(.*)\}")
    id_re = re.compile(r"\bid\s*=\s*(\d+)")
    icon_re = re.compile(r"\bicon\s*=\s*['\"]([^'\"]+)['\"]")
    desc_re = re.compile(r"\bdescription\s*=\s*['\"]([^'\"]+)['\"]")
    param_re = re.compile(r"\bparameter\s*=\s*(\w+)")
    
    with open(spells_lua_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = spell_re.match(line)
            if m:
                name = m.group(1)
                body = m.group(2)
                
                info = {}
                id_m = id_re.search(body)
                if id_m:
                    info['id'] = int(id_m.group(1))
                icon_m = icon_re.search(body)
                if icon_m:
                    info['icon'] = icon_m.group(1)
                desc_m = desc_re.search(body)
                if desc_m:
                    info['description'] = desc_m.group(1)
                param_m = param_re.search(body)
                if param_m:
                    info['parameter'] = param_m.group(1)
                    
                existing[name.lower()] = info
    return existing

def load_existing_spell_icons(spells_lua_path):
    icons = {}
    if not os.path.exists(spells_lua_path):
        return icons
        
    # Match: ['icon'] = {client_id, TFS_id}
    icon_line_re = re.compile(r"^\s*\[['\"]([^'\"]+)['\"]\]\s*=\s*\{(\d+),\s*(\d+)\}")
    with open(spells_lua_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = icon_line_re.match(line)
            if m:
                icons[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    return icons

def parse_spells_xml(xml_path):
    spells = []
    if not os.path.exists(xml_path):
        print(f"Error: spells.xml not found at {xml_path}")
        return spells
        
    try:
        # We parse the XML directly
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        for spell_tag in ["instant", "conjure"]:
            for spell in root.findall(spell_tag):
                name = spell.attrib.get("name")
                words = spell.attrib.get("words")
                if not name or not words:
                    continue
                
                # Skip monster/boss utility spells
                if words.startswith("###"):
                    continue
                
                # Vocation filtering
                vocations = []
                for voc in spell.findall("vocation"):
                    voc_name = voc.attrib.get("name")
                    if voc_name:
                        voc_id = VOCATION_MAP.get(voc_name.lower())
                        if voc_id and voc_id not in vocations:
                            vocations.append(voc_id)
                
                # Skip spells that are not for standard players (no vocations)
                if not vocations:
                    continue
                
                lvl = int(spell.attrib.get("lvl", 1))
                
                mana_str = spell.attrib.get("mana", "0")
                try:
                    mana = int(mana_str)
                except ValueError:
                    mana = "Var."
                    
                soul = int(spell.attrib.get("soul", 0))
                prem = spell.attrib.get("prem") == "1"
                
                spellid_str = spell.attrib.get("spellid")
                spellid = int(spellid_str) if spellid_str else 0
                
                exhaustion = int(spell.attrib.get("exhaustion", 2000))
                groupcooldown = int(spell.attrib.get("groupcooldown", exhaustion))
                
                group_name = spell.attrib.get("group", "support").lower()
                group_id = GROUP_MAP.get(group_name, 3)
                
                is_conjure = spell_tag == "conjure" or spell.attrib.get("function") == "conjureItem"
                spell_type = "Conjure" if is_conjure else "Instant"
                
                parameter = spell.attrib.get("params") == "1"
                
                spells.append({
                    "name": name,
                    "words": words,
                    "level": lvl,
                    "mana": mana,
                    "soul": soul,
                    "premium": prem,
                    "id": spellid,
                    "exhaustion": exhaustion,
                    "groupcooldown": groupcooldown,
                    "group_id": group_id,
                    "type": spell_type,
                    "parameter": parameter,
                    "vocations": sorted(vocations)
                })
    except Exception as e:
        print(f"Error parsing spells.xml: {e}")
        
    return spells

def main():
    print("Loading existing spells.lua configurations...")
    existing_info = load_existing_spells_info(SPELLS_LUA_PATH)
    existing_icons = load_existing_spell_icons(SPELLS_LUA_PATH)
    
    print("Parsing spells.xml...")
    parsed_spells = parse_spells_xml(SPELLS_XML_PATH)
    if not parsed_spells:
        return
        
    print(f"Loaded {len(parsed_spells)} spells from XML.")
    
    # Rebuild database
    spell_order = []
    spell_info = {}
    spell_icons = dict(existing_icons)
    
    for spell in parsed_spells:
        name = spell["name"]
        words = spell["words"]
        name_lower = name.lower()
        
        # Preserve existing mappings if available
        exist = existing_info.get(name_lower, {})
        icon_key = exist.get("icon")
        if not icon_key:
            # Guess icon key based on name
            icon_key = name.lower().replace(" ", "").replace("'", "").replace("-", "")
            
        client_id = exist.get("id")
        if not client_id:
            # If we don't have a client-side icon ID, try getting it from existing icons mapping,
            # or default to the TFS spell ID (or 1 as fallback)
            if icon_key in spell_icons:
                client_id = spell_icons[icon_key][0]
            else:
                client_id = spell["id"] if spell["id"] > 0 else 1
                
        # Register in SpellIcons if not registered
        if icon_key not in spell_icons:
            spell_icons[icon_key] = (client_id, spell["id"])
            
        desc = exist.get("description", "-")
        
        info_entry = {
            "id": client_id,
            "words": words,
            "exhaustion": spell["exhaustion"],
            "premium": spell["premium"],
            "type": spell["type"],
            "icon": icon_key,
            "mana": spell["mana"],
            "level": spell["level"],
            "soul": spell["soul"],
            "group_id": spell["group_id"],
            "groupcooldown": spell["groupcooldown"],
            "vocations": spell["vocations"],
            "description": desc
        }
        
        if spell["parameter"]:
            info_entry["parameter"] = True
            
        spell_info[name] = info_entry
        spell_order.append(name)
        
    # Sort order alphabetically
    spell_order.sort()
    
    # Output the new spells.lua file
    print(f"Writing updated spell list to {SPELLS_LUA_PATH}...")
    try:
        with open(SPELLS_LUA_PATH, "w", encoding="utf-8") as f:
            f.write("-- Automatically compiled from spells.xml by compile-spells.py. Do not edit manually!\n\n")
            
            # SpelllistSettings
            f.write("SpelllistSettings = {\n")
            f.write("  ['Default'] = {\n")
            f.write("    iconFile = '/images/game/spells/defaultspells',\n")
            f.write("    iconSize = {width = 32, height = 32},\n")
            f.write("    spellListWidth = 210,\n")
            f.write("    spellWindowWidth = 550,\n")
            f.write("    spellOrder = {\n")
            for i, name in enumerate(spell_order):
                comma = "," if i < len(spell_order) - 1 else ""
                # Escape single quotes
                safe_name = name.replace("'", "\\'")
                f.write(f"      '{safe_name}'{comma}\n")
            f.write("    }\n")
            f.write("  }\n")
            f.write("}\n\n")
            
            # SpellInfo
            f.write("SpellInfo = {\n")
            f.write("  ['Default'] = {\n")
            for name in sorted(spell_info.keys()):
                info = spell_info[name]
                safe_name = name.replace("'", "\\'")
                safe_words = info["words"].replace("'", "\\'")
                
                # Format premium
                prem_str = "true" if info["premium"] else "false"
                
                # Format mana (could be number or 'Var.')
                mana_val = info["mana"]
                mana_str = f"'{mana_val}'" if isinstance(mana_val, str) else str(mana_val)
                
                # Format group table {[groupId] = groupcooldown}
                group_str = f"{{[{info['group_id']}] = {info['groupcooldown']}}}"
                
                # Format vocations table
                voc_str = "{" + ", ".join(map(str, info["vocations"])) + "}"
                
                # Format parameter
                param_str = ", parameter = true" if info.get("parameter") else ""
                
                # Format description
                desc_str = f", description = '{info['description'].replace(chr(39), chr(92)+chr(39))}'" if info["description"] != "-" else ""
                
                f.write(f"    ['{safe_name}'] = {{id = {info['id']}, words = '{safe_words}', exhaustion = {info['exhaustion']}, premium = {prem_str}, type = '{info['type']}', icon = '{info['icon']}', mana = {mana_str}, level = {info['level']}, soul = {info['soul']}, group = {group_str}, vocations = {voc_str}{param_str}{desc_str}}},\n")
            f.write("  }\n")
            f.write("}\n\n")
            
            # SpellIcons
            f.write("SpellIcons = {\n")
            for icon_key in sorted(spell_icons.keys()):
                client_id, tfs_id = spell_icons[icon_key]
                f.write(f"  ['{icon_key}'] = {{{client_id}, {tfs_id}}},\n")
            f.write("}\n\n")
            
            # VocationNames
            f.write("VocationNames = {\n")
            f.write("  [1] = 'Sorcerer',\n")
            f.write("  [2] = 'Druid',\n")
            f.write("  [3] = 'Paladin',\n")
            f.write("  [4] = 'Knight',\n")
            f.write("  [5] = 'Master Sorcerer',\n")
            f.write("  [6] = 'Elder Druid',\n")
            f.write("  [7] = 'Royal Paladin',\n")
            f.write("  [8] = 'Elite Knight'\n")
            f.write("}\n\n")
            
            # SpellGroups
            f.write("SpellGroups = {\n")
            f.write("  [1] = 'Attack',\n")
            f.write("  [2] = 'Healing',\n")
            f.write("  [3] = 'Support',\n")
            f.write("  [4] = 'Special',\n")
            f.write("  [5] = 'Cripple'\n")
            f.write("}\n\n")
            
            # Append helper functions (hardcoded static part to preserve interface)
            f.write("""Spells = {}

function Spells.getClientId(spellName)
  local profile = Spells.getSpellProfileByName(spellName)

  local id = SpellInfo[profile][spellName].icon
  if not tonumber(id) and SpellIcons[id] then
    return SpellIcons[id][1]
  end
  return tonumber(id)
end

function Spells.getServerId(spellName)
  local profile = Spells.getSpellProfileByName(spellName)

  local id = SpellInfo[profile][spellName].icon
  if not tonumber(id) and SpellIcons[id] then
    return SpellIcons[id][2]
  end
  return tonumber(id)
end

function Spells.getSpellByName(name)
  return SpellInfo[Spells.getSpellProfileByName(name)][name]
end

function Spells.getSpellByWords(words)
  local words = words:lower():trim()
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      if spell.words == words then
        return spell, profile, k
      end
    end
  end
  return nil
end

function Spells.getSpellByIcon(iconId)
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      if spell.id == iconId then
        return spell, profile, k
      end
    end
  end
  return nil
end

function Spells.getSpellIconIds()
  local ids = {}
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      table.insert(ids, spell.id)
    end
  end
  return ids
end

function Spells.getSpellProfileById(id)
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      if spell.id == id then
        return profile
      end
    end
  end
  return nil
end

function Spells.getSpellProfileByWords(words)
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      if spell.words == words then
        return profile
      end
    end
  end
  return nil
end

function Spells.getSpellProfileByName(spellName)
  for profile,data in pairs(SpellInfo) do
    if table.findbykey(data, spellName:trim(), true) then
      return profile
    end
  end
  return nil
end

function Spells.getSpellsByVocationId(vocId)
  local spells = {}
  for profile,data in pairs(SpellInfo) do
    for k,spell in pairs(data) do
      if table.contains(spell.vocations, vocId) then
        table.insert(spells, spell)
      end
    end
  end
  return spells
end

function Spells.filterSpellsByGroups(spells, groups)
  local filtered = {}
  for v,spell in pairs(spells) do
    local spellGroups = Spells.getGroupIds(spell)
    if table.equals(spellGroups, groups) then
      table.insert(filtered, spell)
    end
  end
  return filtered
end

function Spells.getGroupIds(spell)
  local groups = {}
  for k,_ in pairs(spell.group) do
    table.insert(groups, k)
  end
  return groups
end

function Spells.getImageClip(id, profile)
  return (((id-1)%12)*SpelllistSettings[profile].iconSize.width) .. ' ' 
    .. ((math.ceil(id/12)-1)*SpelllistSettings[profile].iconSize.height) .. ' ' 
    .. SpelllistSettings[profile].iconSize.width .. ' ' 
    .. SpelllistSettings[profile].iconSize.height
end

-- Lookup no catalogo local (mesma fonte de icones do Assign Spell / action bar).
function Spells.lookupLocalInfo(spellName, words)
  local spells = SpellInfo['Default']
  if not spells then
    return nil, nil
  end
  if spellName and spells[spellName] then
    return spellName, spells[spellName]
  end
  if words then
    local w = words:lower():trim()
    for name, data in pairs(spells) do
      if data.words and data.words:lower() == w then
        return name, data
      end
    end
  end
  return nil, nil
end

-- Icone de magia instant/conjure: spritesheet defaultspells (SpellInfo.icon).
function Spells.getSpellIcon(spellName, words)
  local name, localData = Spells.lookupLocalInfo(spellName, words)
  local iconKey = (localData and localData.icon) or 'light'
  local iconId = 1
  if SpellIcons[iconKey] then
    iconId = SpellIcons[iconKey][1]
  end
  return {
    kind = 'spell',
    source = SpelllistSettings['Default'].iconFile,
    clip = Spells.getImageClip(iconId, 'Default'),
    name = name or spellName,
  }
end

-- Runa: icon do SpellInfo se existir (ex. Ultimate Healing Rune); senao sprite do item (clientId do .dat).
function Spells.getRuneDisplayIcon(runeName, serverItemId, clientId)
  local name, localData = Spells.lookupLocalInfo(runeName, nil)
  if localData and localData.icon then
    return Spells.getSpellIcon(name, nil)
  end
  local spriteId = clientId
  if (not spriteId or spriteId == 0) and serverItemId and serverItemId > 0 then
    spriteId = serverItemId
  end
  if spriteId and spriteId > 0 then
    return { kind = 'item', clientId = spriteId }
  end
  return nil
end

-- clientId = sprite id do Tibia.dat (nao confundir com server item id do items.xml).
function Spells.applyItemIcon(widget, clientId, count)
  if not widget or not clientId or clientId == 0 then
    return false
  end
  local item = Item.create(clientId, count or 1)
  if item then
    widget:setItem(item)
    return true
  end
  return false
end
""")
            
        print("Success! Spells database compiled successfully.")
    except Exception as e:
        print(f"Error writing spells.lua: {e}")

if __name__ == "__main__":
    main()
