-- WoW Forever (Retail 12.x engine): the same addon files booted against
-- the Forever API shape (m.UseForeverAPI - classic spell / item / skill
-- window / coin globals removed, C_ twins, skills looked up BY ID), plus
-- the Forever rule changes in Data.lua.
local T = _G.WT_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

local AXE1, AXE2, MACE2, POLEARM, SWORD1 = 0, 1, 5, 6, 7
local GREEN, YELLOW, RED = "0.4,0.9,0.4", "1,0.82,0", "1,0.35,0.35"

local function color(line)
    return line.r .. "," .. line.g .. "," .. line.b
end

local function item(subclass) return 9000 + subclass end

local function bootChar(opts)
    return T.boot(opts.flavor or "Forever", function(m)
        m.state.class = opts.class or "WARRIOR"
        m.state.faction = opts.faction or "Alliance"
        m.state.skillsByID = opts.skillsByID or {}
        for _, sub in ipairs({ AXE1, AXE2, MACE2, POLEARM, SWORD1 }) do
            m.state.items[item(sub)] = { classID = 2, subClassID = sub }
        end
        if opts.setup then opts.setup(m) end
    end)
end

test("forever: boots without any classic global", function()
    local B = bootChar({})
    assertTrue(B.ns.isForever, "flavor detected")
    assertEqual(B.env.GetSpellInfo, nil, "mock really is the Forever shape")
    assertEqual(B.env.GetSkillLineInfo, nil, "no skill window api")
    assertEqual(#B.m.__prints, 0, "silent boot")
end)

test("forever: green line from the skill line id, no name matching", function()
    local B = bootChar({ skillsByID = { [43] = { rank = 57, max = 60 } } })
    local lines = B.m.HoverItem(item(SWORD1))
    assertEqual(#lines, 1, "exactly one line")
    assertEqual(lines[1].left, "You can use this weapon (57/60).", "rank from skill 43")
    assertEqual(color(lines[1]), GREEN, "green color")

    -- live lookup, no cache: a skill-up shows on the very next hover
    B.m.state.skillsByID[43].rank = 58
    assertEqual(B.m.HoverItem(item(SWORD1))[1].left, "You can use this weapon (58/60).",
        "no stale cache")
end)

test("forever: a skill learned after login turns green at once", function()
    local B = bootChar({})
    assertEqual(color(B.m.HoverItem(item(POLEARM))[1]), YELLOW, "not learned yet")
    B.m.state.skillsByID[229] = { rank = 1, max = 100 }
    local lines = B.m.HoverItem(item(POLEARM))
    assertEqual(lines[1].left, "You can use this weapon (1/100).", "learned at the trainer")
end)

test("forever: static skill data without a rank is not a known skill", function()
    local B = bootChar({ skillsByID = { [44] = { rank = 0, max = 0 } } })
    local lines = B.m.HoverItem(item(AXE1))
    assertEqual(color(lines[1]), YELLOW, "0/0 is not mine -> still trainable")
end)

test("forever: rankless green when only the spellbook knows the proficiency", function()
    local B = bootChar({ class = "WARLOCK", setup = function(m)
        m.state.knownSpells[201] = true
    end })
    local lines = B.m.HoverItem(item(SWORD1))
    assertEqual(#lines, 1, "one green line")
    assertEqual(lines[1].left, "You can use this weapon.", "via C_SpellBook.IsSpellKnown")
end)

test("forever: yellow lines, cost through C_CurrencyInfo", function()
    local B = bootChar({ faction = "Horde" })
    local lines = B.m.HoverItem(item(AXE1))
    assertEqual(#lines, 2, "city line + cost line")
    assertEqual(lines[1].left, "Can be trained in: Orgrimmar", "horde city")
    assertEqual(lines[2].left, "Training cost: 1000c", "coin string twin")
end)

test("forever: rogues can learn one-handed axes (era: red)", function()
    local F = bootChar({ class = "ROGUE" })
    local lines = F.m.HoverItem(item(AXE1))
    assertEqual(lines[1].left, "Can be trained in: Ironforge", "trainable on Forever")
    assertEqual(color(lines[1]), YELLOW)
    assertEqual(color(F.m.HoverItem(item(AXE2))[1]), RED, "two-handed axes stay red")

    local E = bootChar({ class = "ROGUE", flavor = "Vanilla" })
    assertEqual(color(E.m.HoverItem(item(AXE1))[1]), RED, "era rules untouched")
end)

test("forever: shaman two-handers come from the weapon master, not a talent", function()
    local F = bootChar({ class = "SHAMAN", faction = "Horde" })
    local lines = F.m.HoverItem(item(MACE2))
    assertEqual(lines[1].left, "Can be trained in: Thunder Bluff", "trainer city")
    assertEqual(#lines, 2, "city + cost, no talent hint")

    local E = bootChar({ class = "SHAMAN", flavor = "Vanilla" })
    assertEqual(E.m.HoverItem(item(MACE2))[1].left,
        "Requires the shaman talent 'Two-Handed Axes and Maces'.", "era keeps the talent hint")
end)

test("forever: druid polearms stay red (client table proves nothing)", function()
    local B = bootChar({ class = "DRUID" })
    assertEqual(color(B.m.HoverItem(item(POLEARM))[1]), RED)
end)

test("forever: a secret tooltip payload is skipped, not compared", function()
    local B = bootChar({ setup = function(m)
        m.Enum.TooltipDataType = { Item = 17 }
        m.TooltipDataProcessor = {
            AddTooltipPostCall = function(_, fn) m.__tdp = fn end,
        }
    end })
    B.m.GameTooltip.__lines = {}
    B.m.__tdp(B.m.GameTooltip, { id = B.m.SECRET }) -- must not throw
    assertEqual(#B.m.GameTooltip.__lines, 0, "nothing added")
    B.m.__tdp(B.m.GameTooltip, { id = item(AXE1) })
    assertEqual(B.m.GameTooltip.__lines[1].left, "Can be trained in: Ironforge", "normal ids work")
end)

test("era: the by-id lookup is never used while the skill window exists", function()
    local B = T.boot("Vanilla", function(m)
        m.state.items[item(SWORD1)] = { classID = 2, subClassID = SWORD1 }
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Spell201", rank = 57, max = 300 },
        }
        -- an Era client that grew C_SkillInfo must keep its proven scan
        m.C_SkillInfo = { GetSkillLineInfoByID = function() error("not on era") end }
    end)
    assertEqual(B.m.HoverItem(item(SWORD1))[1].left, "You can use this weapon (57/300).")
end)
