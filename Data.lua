local ADDON_NAME, ns = ...

-- Weapon item subclass IDs (Enum.ItemWeaponSubclass, identical on every
-- client flavor). Subclasses missing here (fishing poles, miscellaneous)
-- get no tooltip lines at all.
local AXE1, AXE2, BOW, GUN, MACE1, MACE2, POLEARM = 0, 1, 2, 3, 4, 5, 6
local SWORD1, SWORD2, STAFF, FIST = 7, 8, 10, 13
local DAGGER, THROWN, CROSSBOW, WAND = 15, 16, 18, 19

-- Weapon proficiency spell per subclass. Locale-safe bridge to the skill
-- window: the spell's localized name is exactly the skill line's name
-- ("Swords", "Two-Handed Swords", ...) on every client language.
ns.PROF_SPELL = {
    [AXE1] = 196, [AXE2] = 197, [BOW] = 264, [GUN] = 266,
    [MACE1] = 198, [MACE2] = 199, [POLEARM] = 200,
    [SWORD1] = 201, [SWORD2] = 202, [STAFF] = 227,
    [FIST] = 15590, [DAGGER] = 1180, [THROWN] = 2567,
    [CROSSBOW] = 5011, [WAND] = 5009,
}

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
