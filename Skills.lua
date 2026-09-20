local ADDON_NAME, ns = ...

-- Known weapon skills with their current/max rank, read from the skill
-- window API (GetSkillLineInfo). Skill lines expose no locale-independent
-- id, so they are matched against the localized names of the proficiency
-- spells from ns.PROF_SPELL. Those names are NOT always identical: the
-- one-handed proficiencies are spells named like "One-Handed Swords"
-- while the skill line is just "Swords". Matching runs in two passes -
-- ns.SKILL_LINE_ALIASES/exact name first, then unique containment of the
-- (case-folded) line name inside a spell name, with IsPlayerSpell
-- breaking 1H-vs-2H ties.
--
-- WoW Forever has no skill window globals at all, but it can look a skill
-- up BY ID (ns.SKILL_LINE, ns.api.GetSkillByID) - no names, no headers, no
-- cache. It wins there; Era / TBC keep the scan they have always used.

local api = ns.api
local SpellName, SpellKnown = api.GetSpellName, api.IsSpellKnown

local useSkillIDs = api.HasSkillByID() and (ns.isForever or not api.HasSkillWindow())

-- string.lower folds only ASCII, but skill lines capitalize letters that
-- sit lowercase inside the spell name ("Äxte" in "Einhandäxte", "Мечи"
-- in "Одноручные мечи"), so Latin-1 and Cyrillic capitals fold by hand.
local function Fold(s)
    s = s:lower()
    s = s:gsub("\195([\128-\158])", function(b) -- UTF-8 À..Þ -> à..þ
        b = b:byte()
        if b ~= 0x97 then return "\195" .. string.char(b + 0x20) end -- × stays
    end)
    s = s:gsub("\208([\129-\175])", function(b) -- UTF-8 Ё,А..Я -> ё,а..я
        b = b:byte()
        if b == 0x81 then return "\209\145" end
        if b >= 0x90 and b <= 0x9F then return "\208" .. string.char(b + 0x20) end
        if b >= 0xA0 then return "\209" .. string.char(b - 0x20) end
    end)
    return s
end

-- subclass -> { name, lower }; rebuilt until every spell name resolved
-- (spell data can be unavailable early after login).
local spellNames, namesComplete
local function BuildNameMap()
    spellNames, namesComplete = {}, true
    for subclass, spellId in pairs(ns.PROF_SPELL) do
        local name = SpellName(spellId)
        if name then
            spellNames[subclass] = { name = name, lower = Fold(name) }
        else
            namesComplete = false
        end
    end
end

-- Collapsed skill headers hide their lines from enumeration, so the scan
-- expands everything and restores the user's collapse state afterwards.
-- Expanding/collapsing fires SKILL_LINES_CHANGED itself; `suppress` keeps
-- those self-inflicted events from re-marking the cache dirty (cleared on
-- the next frame, after they have all been dispatched).
local skillBySubclass = {}
local dirty, suppress = true, false

local function MatchLines(lines)
    wipe(skillBySubclass)

    -- pass 1: locale alias table, then exact spell name == line name
    local exact = {}
    for subclass, spell in pairs(spellNames) do
        exact[spell.name] = subclass
    end
    for _, line in ipairs(lines) do
        local subclass = ns.SKILL_LINE_ALIASES[line.name] or exact[line.name]
        if subclass and not skillBySubclass[subclass] then
            skillBySubclass[subclass] = { rank = line.rank, max = line.max }
            line.matched = true
        end
    end

    -- pass 2: line name contained in a spell name ("Swords" in
    -- "One-Handed Swords"). Both 1H and 2H can still be candidates when
    -- the 2H line is absent; only the known proficiency can be the one
    -- producing a skill line.
    for _, line in ipairs(lines) do
        if not line.matched then
            local lower = Fold(line.name)
            local hits = {}
            for subclass, spell in pairs(spellNames) do
                if not skillBySubclass[subclass] and spell.lower:find(lower, 1, true) then
                    hits[#hits + 1] = subclass
                end
            end
            if #hits > 1 then
                local known = {}
                for _, subclass in ipairs(hits) do
                    if SpellKnown(ns.PROF_SPELL[subclass]) then
                        known[#known + 1] = subclass
                    end
                end
                if #known > 0 then hits = known end
            end
            if #hits == 1 then
                skillBySubclass[hits[1]] = { rank = line.rank, max = line.max }
            end
        end
    end
end

local function Rescan()
    if not namesComplete then BuildNameMap() end
    suppress = true
    local toggled = false

    local collapsed = {}
    local i = 1
    while i <= GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if isHeader and not isExpanded then
            collapsed[name] = true
            toggled = true
            ExpandSkillHeader(i)
        end
        i = i + 1
    end

    local lines = {}
    for j = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(j)
        if not isHeader and name then
            lines[#lines + 1] = { name = name, rank = rank or 0, max = maxRank or 0 }
        end
    end

    for j = GetNumSkillLines(), 1, -1 do
        local name, isHeader = GetSkillLineInfo(j)
        if isHeader and collapsed[name] then CollapseSkillHeader(j) end
    end

    MatchLines(lines)

    dirty = false
    -- Untouched headers mean no self-inflicted events: lift the
    -- suppression immediately so no real skill-up event is ever dropped.
    if toggled then
        C_Timer.After(0, function() suppress = false end)
    else
        suppress = false
    end
end

-- Current rank and max for a weapon subclass, or nil when the skill is
-- not known. Rescans lazily, so mid-combat skill-ups cost nothing until
-- the next tooltip actually asks.
function ns.GetWeaponSkill(subclass)
    if useSkillIDs then return api.GetSkillByID(ns.SKILL_LINE[subclass]) end
    if not api.HasSkillWindow() then return nil end -- unknown client: no rank
    if dirty then Rescan() end
    local s = skillBySubclass[subclass]
    if s then return s.rank, s.max end
end

-- Whether the proficiency is known at all, even when the skill window
-- scan could not resolve its line (a locale whose skill line name has no
-- relation to the spell name). Rank is unavailable in that case.
function ns.IsWeaponSkillKnown(subclass)
    if ns.GetWeaponSkill(subclass) then return true end
    local spellId = ns.PROF_SPELL[subclass]
    return (spellId and SpellKnown(spellId)) or false
end

-- the by-id lookup is always live; only the scan has a cache to invalidate
if not useSkillIDs then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("SKILL_LINES_CHANGED")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function()
        if not suppress then dirty = true end
    end)
end
