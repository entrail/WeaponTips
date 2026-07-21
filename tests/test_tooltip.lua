-- End-to-end tooltip behavior through the real hook pipeline, colors
-- included (they ARE the feature). Items are synthetic: 9000+subclass,
-- classID 2 = weapon. Cost renders via the mock's GetCoinTextureString
-- as "<copper>c".
local T = _G.WT_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

local AXE1, MACE2, POLEARM, SWORD1, WAND = 0, 5, 6, 7, 19
local GREEN, YELLOW, RED = "0.4,0.9,0.4", "1,0.82,0", "1,0.35,0.35"

local function color(line)
    return line.r .. "," .. line.g .. "," .. line.b
end

local function item(subclass) return 9000 + subclass end

-- boot with a weapon item per subclass under test and optional skills
local function bootChar(opts)
    return T.boot(opts.flavor or "Vanilla", function(m)
        m.state.class = opts.class or "WARRIOR"
        m.state.faction = opts.faction or "Alliance"
        m.state.skills = opts.skills or {}
        for _, sub in ipairs({ AXE1, MACE2, POLEARM, SWORD1, WAND }) do
            m.state.items[item(sub)] = { classID = 2, subClassID = sub }
        end
        m.state.items[8020] = { classID = 2, subClassID = 20 } -- fishing pole
        m.state.items[8004] = { classID = 4, subClassID = 1 }  -- armor, not a weapon
    end)
end

test("tooltip: green line with current/max skill", function()
    local B = bootChar({ skills = {
        { header = "Weapon Skills", expanded = true },
        { name = "Spell201", rank = 57, max = 300 },
    } })
    local lines = B.m.HoverItem(item(SWORD1))
    assertEqual(#lines, 1, "exactly one line")
    assertEqual(lines[1].left, "You can use this weapon (57/300).", "green text")
    assertEqual(color(lines[1]), GREEN, "green color")
end)

test("tooltip: yellow lines with faction cities and cost", function()
    local B = bootChar({})
    local lines = B.m.HoverItem(item(AXE1))
    assertEqual(#lines, 2, "city line + cost line")
    assertEqual(lines[1].left, "Can be trained in: Ironforge", "alliance city")
    assertEqual(lines[2].left, "Training cost: 1000c", "10s, no level requirement")
    assertEqual(color(lines[1]), YELLOW, "yellow city line")
    assertEqual(color(lines[2]), YELLOW, "yellow cost line")

    local H = bootChar({ faction = "Horde" })
    local hlines = H.m.HoverItem(item(AXE1))
    assertEqual(hlines[1].left, "Can be trained in: Orgrimmar", "horde city")
end)

test("tooltip: polearms show 1g and the level 20 requirement", function()
    local B = bootChar({})
    local lines = B.m.HoverItem(item(POLEARM))
    assertEqual(lines[1].left, "Can be trained in: Stormwind City", "polearm city")
    assertEqual(lines[2].left, "Training cost: 10000c (from level 20)", "cost + level")
end)

test("tooltip: localized city names win over the English fallback", function()
    local B = T.boot("Vanilla", function(m)
        m.state.class = "WARRIOR"
        m.state.items[item(AXE1)] = { classID = 2, subClassID = AXE1 }
        m.state.mapNames[1455] = "Eisenschmiede"
    end)
    local lines = B.m.HoverItem(item(AXE1))
    assertEqual(lines[1].left, "Can be trained in: Eisenschmiede", "C_Map name used")
end)

test("tooltip: red line for never-usable types", function()
    local B = bootChar({ class = "PRIEST" })
    local lines = B.m.HoverItem(item(SWORD1))
    assertEqual(#lines, 1, "one red line")
    assertEqual(lines[1].left, "Your class cannot use this type of weapon.", "red text")
    assertEqual(color(lines[1]), RED, "red color")
end)

test("tooltip: shaman two-handers point at the talent, not a trainer", function()
    local B = bootChar({ class = "SHAMAN" })
    local lines = B.m.HoverItem(item(MACE2))
    assertEqual(#lines, 1, "talent hint only")
    assertEqual(lines[1].left,
        "Requires the shaman talent 'Two-Handed Axes and Maces'.", "talent text")
    assertEqual(color(lines[1]), YELLOW, "talent hint is yellow")
end)

test("tooltip: unlearnable-nowhere types stay silent (wand w/o skill)", function()
    local B = bootChar({ class = "MAGE" })
    local lines = B.m.HoverItem(item(WAND))
    assertEqual(#lines, 0, "no trainer, no lines")
end)

test("tooltip: fishing poles and non-weapons are ignored", function()
    local B = bootChar({})
    assertEqual(#B.m.HoverItem(8020), 0, "fishing pole silent")
    assertEqual(#B.m.HoverItem(8004), 0, "armor silent")
    assertEqual(#B.m.HoverItem(7777), 0, "unknown item silent")
end)

test("tooltip: each line type can be toggled off", function()
    local B = bootChar({ skills = {
        { header = "Weapon Skills", expanded = true },
        { name = "Spell201", rank = 57, max = 300 },
    } })
    B.ns.db.showUsable = false
    assertEqual(#B.m.HoverItem(item(SWORD1)), 0, "green off")

    B.ns.db.showTrainable = false
    assertEqual(#B.m.HoverItem(item(AXE1)), 0, "yellow off")

    local P = bootChar({ class = "PRIEST" })
    P.ns.db.showUnusable = false
    assertEqual(#P.m.HoverItem(item(SWORD1)), 0, "red off")
end)

test("tooltip: ItemRefTooltip (chat links) gets the same lines", function()
    local B = bootChar({})
    local lines = B.m.HoverItem(item(AXE1), B.m.ItemRefTooltip)
    assertEqual(#lines, 2, "chat link tooltip works")
    assertEqual(lines[1].left, "Can be trained in: Ironforge", "same content")
end)

test("tooltip: modern TooltipDataProcessor path", function()
    local B = T.boot("Vanilla", function(m)
        m.state.class = "WARRIOR"
        m.state.items[item(AXE1)] = { classID = 2, subClassID = AXE1 }
        m.Enum = { ItemClass = { Weapon = 2 }, TooltipDataType = { Item = 17 } }
        m.TooltipDataProcessor = {
            AddTooltipPostCall = function(dataType, fn)
                m.__tdpType, m.__tdp = dataType, fn
            end,
        }
    end)
    assertEqual(B.m.__tdpType, 17, "registered for item tooltips")
    assertEqual(#(B.m.GameTooltip.__hooks.OnTooltipSetItem or {}), 0,
        "no legacy hooks on the modern path")

    B.m.GameTooltip.__lines = {}
    B.m.__tdp(B.m.GameTooltip, { id = item(AXE1) })
    assertEqual(B.m.GameTooltip.__lines[1].left, "Can be trained in: Ironforge",
        "post-call adds the lines")

    local foreign = { __lines = {} }
    B.m.__tdp(foreign, { id = item(AXE1) }) -- must not error, must not add
    assertEqual(#foreign.__lines, 0, "foreign tooltips ignored")
end)
