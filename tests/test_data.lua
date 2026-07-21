-- Data integrity: proficiency spells, class matrix and trainer tables.
-- The class rules are pinned to the Classic/TBC era (no rogue axes, no
-- druid polearms) and the trainer cities to the anniversary-realm weapon
-- masters - a data edit that changes them must be deliberate.
local T = _G.WT_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

local AXE1, AXE2, BOW, GUN, MACE1, MACE2, POLEARM = 0, 1, 2, 3, 4, 5, 6
local SWORD1, SWORD2, STAFF, FIST = 7, 8, 10, 13
local DAGGER, THROWN, CROSSBOW, WAND = 15, 16, 18, 19
local SW, OG, UC, TB, IF, DA, EX, SM = 1453, 1454, 1458, 1456, 1455, 1457, 1947, 1954

local V = T.boot("Vanilla")
local B = T.boot("TBC")

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function cityMaps(booted, subclass, faction)
    local maps = {}
    for _, city in ipairs(booted.ns.TRAINERS[subclass][faction]) do
        maps[#maps + 1] = city.map
    end
    table.sort(maps)
    return table.concat(maps, ",")
end

test("data: every weapon subclass has a proficiency spell and trainer entry", function()
    assertEqual(count(V.ns.PROF_SPELL), 15, "subclass count")
    for subclass, spellId in pairs(V.ns.PROF_SPELL) do
        assertTrue(type(spellId) == "number" and spellId > 0, "spell for subclass " .. subclass)
        local trainers = V.ns.TRAINERS[subclass]
        assertTrue(trainers and trainers.Alliance and trainers.Horde,
            "trainer entry for subclass " .. subclass)
    end
    for subclass in pairs(V.ns.TRAINERS) do
        assertTrue(V.ns.PROF_SPELL[subclass], "orphan trainer entry " .. subclass)
    end
end)

test("data: class matrix pins the era's rules", function()
    local sizes = { WARRIOR = 14, HUNTER = 12, ROGUE = 8, PALADIN = 7,
        SHAMAN = 7, DRUID = 5, PRIEST = 4, MAGE = 4, WARLOCK = 4 }
    assertEqual(count(V.ns.CLASS_WEAPONS), 9, "nine classes")
    for class, want in pairs(sizes) do
        assertEqual(count(V.ns.CLASS_WEAPONS[class]), want, class .. " weapon count")
    end
    -- era rules that later expansions changed
    assertFalse(V.ns.CLASS_WEAPONS.ROGUE[AXE1], "no rogue axes before Cataclysm")
    assertFalse(V.ns.CLASS_WEAPONS.DRUID[POLEARM], "no druid polearms before Cataclysm")
    assertFalse(V.ns.CLASS_WEAPONS.PALADIN[DAGGER], "no paladin daggers in this era")
    assertFalse(V.ns.CLASS_WEAPONS.WARRIOR[WAND], "warriors never wand")
    assertTrue(V.ns.CLASS_WEAPONS.HUNTER[STAFF], "hunters can learn staves")
    assertTrue(V.ns.CLASS_WEAPONS.DRUID[MACE2], "druids can learn 2H maces")
    -- shaman two-handers exist in the matrix but are talent-gated
    assertTrue(V.ns.CLASS_WEAPONS.SHAMAN[AXE2] and V.ns.CLASS_WEAPONS.SHAMAN[MACE2],
        "shaman two-handers in matrix")
    assertTrue(V.ns.TALENT_WEAPONS.SHAMAN[AXE2] and V.ns.TALENT_WEAPONS.SHAMAN[MACE2],
        "shaman two-handers talent-gated")
    assertEqual(count(V.ns.TALENT_WEAPONS.SHAMAN), 2, "only the two shaman skills")
end)

test("data: vanilla trainer cities match the anniversary weapon masters", function()
    assertEqual(cityMaps(V, AXE1, "Alliance"), tostring(IF), "axes A")
    assertEqual(cityMaps(V, AXE1, "Horde"), tostring(OG), "axes H")
    assertEqual(cityMaps(V, GUN, "Alliance"), tostring(IF), "guns A")
    assertEqual(cityMaps(V, GUN, "Horde"), tostring(TB), "guns H")
    assertEqual(cityMaps(V, SWORD1, "Alliance"), tostring(SW), "swords A")
    assertEqual(cityMaps(V, SWORD1, "Horde"), tostring(UC), "swords H")
    assertEqual(cityMaps(V, POLEARM, "Horde"), tostring(UC), "polearms H")
    assertEqual(cityMaps(V, STAFF, "Alliance"), SW .. "," .. DA, "staves A")
    assertEqual(cityMaps(V, STAFF, "Horde"), OG .. "," .. TB, "staves H")
    assertEqual(cityMaps(V, DAGGER, "Alliance"), SW .. "," .. IF .. "," .. DA, "daggers A")
    assertEqual(cityMaps(V, DAGGER, "Horde"), OG .. "," .. UC, "daggers H")
    assertEqual(cityMaps(V, WAND, "Alliance"), "", "wands have no trainer")
    -- no TBC city may leak into a vanilla boot
    for subclass in pairs(V.ns.TRAINERS) do
        for _, faction in ipairs({ "Alliance", "Horde" }) do
            for _, city in ipairs(V.ns.TRAINERS[subclass][faction]) do
                assertTrue(city.map ~= EX and city.map ~= SM,
                    "TBC city in vanilla data, subclass " .. subclass)
            end
        end
    end
end)

test("data: TBC adds exactly Ileda (Silvermoon) and Handiir (Exodar)", function()
    -- Ileda: daggers, 1H/2H swords, bows, polearms (Horde)
    assertEqual(cityMaps(B, DAGGER, "Horde"), OG .. "," .. UC .. "," .. SM, "TBC daggers H")
    assertEqual(cityMaps(B, SWORD2, "Horde"), UC .. "," .. SM, "TBC 2H swords H")
    assertEqual(cityMaps(B, BOW, "Horde"), OG .. "," .. SM, "TBC bows H")
    assertEqual(cityMaps(B, POLEARM, "Horde"), UC .. "," .. SM, "TBC polearms H")
    -- Handiir: crossbows, daggers, 1H/2H maces, 1H/2H swords (Alliance)
    assertEqual(cityMaps(B, CROSSBOW, "Alliance"), SW .. "," .. IF .. "," .. EX, "TBC crossbows A")
    assertEqual(cityMaps(B, MACE1, "Alliance"), IF .. "," .. EX, "TBC maces A")
    assertEqual(cityMaps(B, SWORD1, "Alliance"), SW .. "," .. EX, "TBC swords A")
    assertEqual(cityMaps(B, DAGGER, "Alliance"), SW .. "," .. IF .. "," .. DA .. "," .. EX, "TBC daggers A")
    -- and nothing else changes
    assertEqual(cityMaps(B, CROSSBOW, "Horde"), tostring(UC), "TBC crossbows H unchanged")
    assertEqual(cityMaps(B, BOW, "Alliance"), tostring(DA), "TBC bows A unchanged")
    assertEqual(cityMaps(B, GUN, "Alliance"), tostring(IF), "TBC guns A unchanged")
    assertEqual(cityMaps(B, THROWN, "Horde"), tostring(OG), "TBC thrown H unchanged")
end)

test("data: training cost and level requirement", function()
    assertEqual(V.ns.TRAIN_COST_DEFAULT, 1000, "default cost 10s")
    assertEqual(V.ns.TRAIN_COST[POLEARM], 10000, "polearms cost 1g")
    assertEqual(count(V.ns.TRAIN_COST), 1, "only polearms differ")
    assertEqual(V.ns.TRAIN_LEVEL[POLEARM], 20, "polearms from level 20")
    assertEqual(count(V.ns.TRAIN_LEVEL), 1, "only polearms have a level")
end)

test("data: flavor flag drives the data split", function()
    assertFalse(V.ns.isTBC, "vanilla boot")
    assertTrue(B.ns.isTBC, "TBC boot")
end)
