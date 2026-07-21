-- Skill window scanning: lazy rescan, collapsed-header handling with
-- state restore, and suppression of the scan's own SKILL_LINES_CHANGED
-- events (the mock fires them synchronously from Expand/Collapse, like
-- the client). Skill names use the mock's "Spell<id>" spell names, which
-- is exactly the addon's locale-safe matching path.
local T = _G.WT_TEST
local test, assertEqual, assertTrue, assertFalse =
    T.test, T.assertEqual, T.assertTrue, T.assertFalse

local SWORD1, DAGGER = 7, 15

local function warriorWithSkills(skills)
    return T.boot("Vanilla", function(m)
        m.state.skills = skills
    end)
end

test("skills: known skill returns rank and max, unknown returns nil", function()
    local B = warriorWithSkills({
        { header = "Weapon Skills", expanded = true },
        { name = "Spell201", rank = 57, max = 300 },  -- Swords
        { name = "Unrelated Skill", rank = 5, max = 75 },
    })
    local rank, max = B.ns.GetWeaponSkill(SWORD1)
    assertEqual(rank, 57, "sword rank")
    assertEqual(max, 300, "sword max")
    assertEqual(B.ns.GetWeaponSkill(DAGGER), nil, "daggers unknown")
end)

test("skills: collapsed headers are scanned and their state restored", function()
    local B = warriorWithSkills({
        { header = "Class Skills", expanded = true },
        { name = "Some Spell", rank = 1, max = 1 },
        { header = "Weapon Skills", expanded = false },
        { name = "Spell201", rank = 42, max = 150 },
    })
    local rank = B.ns.GetWeaponSkill(SWORD1)
    assertEqual(rank, 42, "skill found behind collapsed header")
    assertFalse(B.m.state.skills[3].expanded, "collapsed header restored")
    assertTrue(B.m.state.skills[1].expanded, "expanded header untouched")
end)

test("skills: scan-inflicted events are suppressed, real ones rescan", function()
    local B = warriorWithSkills({
        { header = "Weapon Skills", expanded = false },
        { name = "Spell201", rank = 42, max = 150 },
    })
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 42, "initial scan")
    B.m.RunTimers() -- next frame: suppression window closes

    -- rank changes WITHOUT an event: the cache must NOT have gone dirty
    -- from the scan's own expand/collapse events
    B.m.state.skills[2].rank = 99
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 42, "cache clean, no self-dirty loop")

    -- a real skill-up event rescans
    B.m.Fire("SKILL_LINES_CHANGED")
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 99, "event marks dirty, rescan picks up")
end)

test("skills: learning a new skill appears after the event", function()
    local B = warriorWithSkills({
        { header = "Weapon Skills", expanded = true },
        { name = "Spell201", rank = 10, max = 50 },
    })
    assertEqual(B.ns.GetWeaponSkill(DAGGER), nil, "daggers not learned yet")
    table.insert(B.m.state.skills, { name = "Spell1180", rank = 1, max = 50 })
    B.m.Fire("SKILL_LINES_CHANGED")
    local rank, max = B.ns.GetWeaponSkill(DAGGER)
    assertEqual(rank, 1, "daggers picked up")
    assertEqual(max, 50, "daggers max")
end)
