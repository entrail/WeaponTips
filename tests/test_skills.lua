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

-- Live-client names: the 1H proficiency SPELLS are "One-Handed Swords"
-- (201) etc., but the skill LINE is just "Swords" - exact matching alone
-- left every known 1H axe/mace/sword skill looking untrained (the
-- learned-but-still-yellow tooltip bug).
local function liveNames(m)
    m.state.spellNames[201] = "One-Handed Swords"
    m.state.spellNames[202] = "Two-Handed Swords"
end

test("skills: 1H line 'Swords' resolves via substring + IsPlayerSpell", function()
    local B = T.boot("Vanilla", function(m)
        liveNames(m)
        m.state.knownSpells[201] = true
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Swords", rank = 15, max = 55 },
        }
    end)
    local rank, max = B.ns.GetWeaponSkill(SWORD1)
    assertEqual(rank, 15, "1H swords rank found despite name mismatch")
    assertEqual(max, 55, "1H swords max")
    assertEqual(B.ns.GetWeaponSkill(8), nil, "2H swords still unknown")
end)

test("skills: TBC flavor resolves the 1H name mismatch the same way", function()
    local B = T.boot("TBC", function(m)
        liveNames(m)
        m.state.knownSpells[201] = true
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Swords", rank = 220, max = 350 },
        }
    end)
    local rank, max = B.ns.GetWeaponSkill(SWORD1)
    assertEqual(rank, 220, "1H swords rank found on TBC")
    assertEqual(max, 350, "TBC max rank")
end)

test("skills: 1H and 2H both known resolve to their own lines", function()
    local B = T.boot("Vanilla", function(m)
        liveNames(m)
        m.state.knownSpells[201] = true
        m.state.knownSpells[202] = true
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Two-Handed Swords", rank = 30, max = 60 },
            { name = "Swords", rank = 15, max = 55 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 15, "1H via containment")
    assertEqual(B.ns.GetWeaponSkill(8), 30, "2H via exact match")
end)

test("skills: ambiguous containment without known-spell info stays nil", function()
    local B = T.boot("Vanilla", function(m)
        liveNames(m)
        m.IsPlayerSpell = nil -- no tie-breaker available
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Swords", rank = 15, max = 55 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), nil, "no guess between 1H and 2H")
end)

test("skills: IsWeaponSkillKnown covers unresolvable skill line names", function()
    local B = T.boot("Vanilla", function(m)
        m.state.knownSpells[201] = true
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Totally Different Word", rank = 15, max = 55 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), nil, "no rank resolvable")
    assertTrue(B.ns.IsWeaponSkillKnown(SWORD1), "known via IsPlayerSpell")
    assertFalse(B.ns.IsWeaponSkillKnown(DAGGER), "unknown stays unknown")
end)

test("skills: German umlaut capitals fold ('Äxte' in 'Einhandäxte')", function()
    local B = T.boot("Vanilla", function(m)
        m.state.spellNames[196] = "Einhandäxte"
        m.state.spellNames[197] = "Zweihandäxte"
        m.state.knownSpells[196] = true
        m.state.skills = {
            { header = "Waffenfertigkeiten", expanded = true },
            { name = "Äxte", rank = 20, max = 55 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(0), 20, "umlaut line folded and matched")
end)

test("skills: Cyrillic capitals fold ('Мечи' in 'Одноручные мечи')", function()
    local B = T.boot("Vanilla", function(m)
        m.state.spellNames[201] = "Одноручные мечи"
        m.state.spellNames[202] = "Двуручные мечи"
        m.state.knownSpells[201] = true
        m.state.skills = {
            { header = "Оружие", expanded = true },
            { name = "Мечи", rank = 33, max = 60 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 33, "cyrillic line folded and matched")
end)

test("skills: ruRU alias lines resolve without any name overlap", function()
    local B = T.boot("Vanilla", function(m)
        m.GetLocale = function() return "ruRU" end
        m.state.spellNames[198] = "Одноручное ударное оружие"
        m.state.skills = {
            { header = "Оружие", expanded = true },
            { name = "Дробящее оружие", rank = 44, max = 60 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(4), 44, "ru maces via alias table")
end)

test("skills: koKR alias lines resolve without any name overlap", function()
    local B = T.boot("Vanilla", function(m)
        m.GetLocale = function() return "koKR" end
        m.state.spellNames[201] = "한손 검"
        m.state.skills = {
            { header = "무기 기술", expanded = true },
            { name = "도검류", rank = 55, max = 60 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 55, "ko swords via alias table")
end)

test("skills: incomplete spell names are re-fetched on later scans", function()
    local B = T.boot("Vanilla", function(m)
        m.state.spellNames[201] = false -- spell data not loaded yet
        m.state.skills = {
            { header = "Weapon Skills", expanded = true },
            { name = "Spell201", rank = 15, max = 55 },
        }
    end)
    assertEqual(B.ns.GetWeaponSkill(SWORD1), nil, "name unavailable, no match")
    B.m.state.spellNames[201] = nil -- data arrives
    B.m.Fire("SKILL_LINES_CHANGED")
    assertEqual(B.ns.GetWeaponSkill(SWORD1), 15, "name map rebuilt, match found")
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
