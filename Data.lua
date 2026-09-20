local ADDON_NAME, ns = ...

-- Weapon item subclass IDs (Enum.ItemWeaponSubclass, identical on every
-- client flavor). Subclasses missing here (fishing poles, miscellaneous)
-- get no tooltip lines at all.
local AXE1, AXE2, BOW, GUN, MACE1, MACE2, POLEARM = 0, 1, 2, 3, 4, 5, 6
local SWORD1, SWORD2, STAFF, FIST = 7, 8, 10, 13
local DAGGER, THROWN, CROSSBOW, WAND = 15, 16, 18, 19

-- Weapon proficiency spell per subclass. Locale-safe bridge to the skill
-- window: the skill line's name matches the spell's localized name -
-- exactly for most ("Two-Handed Swords", "Daggers", ...), for the
-- one-handed ones as a substring (skill line "Swords", spell
-- "One-Handed Swords"); Skills.lua handles both.
ns.PROF_SPELL = {
    [AXE1] = 196, [AXE2] = 197, [BOW] = 264, [GUN] = 266,
    [MACE1] = 198, [MACE2] = 199, [POLEARM] = 200,
    [SWORD1] = 201, [SWORD2] = 202, [STAFF] = 227,
    [FIST] = 15590, [DAGGER] = 1180, [THROWN] = 2567,
    [CROSSBOW] = 5011, [WAND] = 5009,
}

-- Skill line id per subclass (SkillLine.db2, identical on Era, TBC and
-- Forever). Only Forever can look a skill up by id - the classic skill
-- window API knows nothing but localized names - see Skills.lua.
ns.SKILL_LINE = {
    [AXE1] = 44, [AXE2] = 172, [BOW] = 45, [GUN] = 46,
    [MACE1] = 54, [MACE2] = 160, [POLEARM] = 229,
    [SWORD1] = 43, [SWORD2] = 55, [STAFF] = 136,
    [FIST] = 473, [DAGGER] = 173, [THROWN] = 176,
    [CROSSBOW] = 226, [WAND] = 228,
}

-- Skill window lines whose localized names share no substring with their
-- proficiency spell, so neither exact nor containment matching can find
-- them: Russian renames a few lines outright, Korean appends a "type of"
-- suffix to most. Exact line name -> subclass, verified against wowhead
-- classic data. Other locales resolve via the name passes in Skills.lua.
ns.SKILL_LINE_ALIASES = ({
    ruRU = {
        ["Огнестрельное оружие"] = GUN,       -- spell: "Ружья"
        ["Дробящее оружие"] = MACE1,          -- spell: "Одноручное ударное оружие"
        ["Двуручное дробящее оружие"] = MACE2, -- spell: "Двуручное ударное оружие"
        ["Метательное оружие"] = THROWN,      -- spell: "Бросок"
    },
    koKR = {
        ["도끼류"] = AXE1, ["양손 도끼류"] = AXE2,
        ["활류"] = BOW, ["총기류"] = GUN,
        ["둔기류"] = MACE1, ["양손 둔기류"] = MACE2,
        ["도검류"] = SWORD1, ["양손 도검류"] = SWORD2,
        ["지팡이류"] = STAFF, ["단검류"] = DAGGER,
        ["투척 무기류"] = THROWN, ["석궁류"] = CROSSBOW,
        ["마법봉류"] = WAND,
    },
})[GetLocale()] or {}

-- Which weapon types each class can ever learn (Classic and TBC use the
-- same matrix; rogue axes and druid polearms only came with Cataclysm).
-- Wands are never trained - the classes that can use them start with the
-- skill - so they only ever hit the green or red path.
local function set(...)
    local t = {}
    for i = 1, select("#", ...) do t[select(i, ...)] = true end
    return t
end

ns.CLASS_WEAPONS = {
    WARRIOR = set(AXE1, AXE2, BOW, GUN, MACE1, MACE2, POLEARM, SWORD1, SWORD2, STAFF, FIST, DAGGER, THROWN, CROSSBOW),
    PALADIN = set(AXE1, AXE2, MACE1, MACE2, POLEARM, SWORD1, SWORD2),
    HUNTER  = set(AXE1, AXE2, BOW, GUN, POLEARM, SWORD1, SWORD2, STAFF, FIST, DAGGER, THROWN, CROSSBOW),
    ROGUE   = set(BOW, GUN, CROSSBOW, MACE1, SWORD1, FIST, DAGGER, THROWN),
    PRIEST  = set(MACE1, STAFF, DAGGER, WAND),
    SHAMAN  = set(AXE1, AXE2, MACE1, MACE2, STAFF, FIST, DAGGER),
    MAGE    = set(SWORD1, STAFF, DAGGER, WAND),
    WARLOCK = set(SWORD1, STAFF, DAGGER, WAND),
    DRUID   = set(MACE1, MACE2, STAFF, FIST, DAGGER),
}

-- Weapon types no weapon master teaches: shamans get two-handed axes and
-- maces only through the Enhancement talent of the same name.
ns.TALENT_WEAPONS = {
    SHAMAN = set(AXE2, MACE2),
}

-- WoW Forever rule changes (SkillRaceClassInfo of build 1.60.1.69913
-- diffed against Era):
--   * rogues can learn one-handed axes
--   * the shaman talent 'Two-Handed Axes and Maces' left the talent trees
--     and the two skills turned from talent-granted into ordinary learnable
--     ones, like everybody else's -> they get the weapon master cities
-- Druid polearms stay red: the client table allows them on Era as well
-- (Season of Discovery rows), so it proves nothing for Forever. A druid
-- who does learn them gets the green line regardless.
-- Weapon master cities and prices are server-side trainer data, invisible
-- to the client DB: Forever reuses the Era values below until an in-game
-- check says otherwise (the polearm level 20 IS in the client table).
if ns.isForever then
    ns.CLASS_WEAPONS.ROGUE[AXE1] = true
    ns.TALENT_WEAPONS = {}
end

-- Cities with a weapon master, as uiMapIDs so C_Map.GetMapInfo returns
-- the localized city name; the English name is only a fallback.
local SW = { map = 1453, name = "Stormwind City" }
local IF = { map = 1455, name = "Ironforge" }
local DA = { map = 1457, name = "Darnassus" }
local EX = { map = 1947, name = "The Exodar" }      -- TBC only
local OG = { map = 1454, name = "Orgrimmar" }
local UC = { map = 1458, name = "Undercity" }
local TB = { map = 1456, name = "Thunder Bluff" }
local SM = { map = 1954, name = "Silvermoon City" } -- TBC only

-- Weapon masters per skill and faction, verified against the anniversary
-- realm trainers. TBC adds Ileda in Silvermoon (daggers, swords, bows,
-- polearms) and Handiir in the Exodar (crossbows, daggers, maces, swords).
local tbc = ns.isTBC
local function cities(base, extra)
    if tbc and extra then
        local merged = {}
        for _, c in ipairs(base) do merged[#merged + 1] = c end
        for _, c in ipairs(extra) do merged[#merged + 1] = c end
        return merged
    end
    return base
end

-- Weapon master training cost (in copper) and required character level:
-- every skill is 10 silver with no level requirement, except polearms
-- (1 gold, level 20). Identical on Classic and TBC.
ns.TRAIN_COST_DEFAULT = 1000
ns.TRAIN_COST = { [POLEARM] = 10000 }
ns.TRAIN_LEVEL = { [POLEARM] = 20 }

ns.TRAINERS = {
    [AXE1]     = { Alliance = { IF },             Horde = { OG } },
    [AXE2]     = { Alliance = { IF },             Horde = { OG } },
    [BOW]      = { Alliance = { DA },             Horde = cities({ OG }, { SM }) },
    [GUN]      = { Alliance = { IF },             Horde = { TB } },
    [MACE1]    = { Alliance = cities({ IF }, { EX }), Horde = { TB } },
    [MACE2]    = { Alliance = cities({ IF }, { EX }), Horde = { TB } },
    [POLEARM]  = { Alliance = { SW },             Horde = cities({ UC }, { SM }) },
    [SWORD1]   = { Alliance = cities({ SW }, { EX }), Horde = cities({ UC }, { SM }) },
    [SWORD2]   = { Alliance = cities({ SW }, { EX }), Horde = cities({ UC }, { SM }) },
    [STAFF]    = { Alliance = { SW, DA },         Horde = { OG, TB } },
    [FIST]     = { Alliance = { IF, DA },         Horde = { OG } },
    [DAGGER]   = { Alliance = cities({ SW, IF, DA }, { EX }), Horde = cities({ OG, UC }, { SM }) },
    [THROWN]   = { Alliance = { IF, DA },         Horde = { OG } },
    [CROSSBOW] = { Alliance = cities({ SW, IF }, { EX }), Horde = { UC } },
    [WAND]     = { Alliance = {},                 Horde = {} },
}
