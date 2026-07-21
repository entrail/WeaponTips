local ADDON_NAME, ns = ...

-- Known weapon skills with their current/max rank, read from the skill
-- window API (GetSkillLineInfo). Skill line names are localized, so they
-- are matched against the localized names of the proficiency spells from
-- ns.PROF_SPELL - both come from the client, identical on every locale.

local function SpellName(spellId)
    if GetSpellInfo then
        return (GetSpellInfo(spellId))
    end
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellId)
    end
end

local nameToSubclass
local function BuildNameMap()
    nameToSubclass = {}
    for subclass, spellId in pairs(ns.PROF_SPELL) do
        local name = SpellName(spellId)
        if name then nameToSubclass[name] = subclass end
    end
end

-- Collapsed skill headers hide their lines from enumeration, so the scan
-- expands everything and restores the user's collapse state afterwards.
-- Expanding/collapsing fires SKILL_LINES_CHANGED itself; `suppress` keeps
-- those self-inflicted events from re-marking the cache dirty (cleared on
-- the next frame, after they have all been dispatched).
local skillBySubclass = {}
local dirty, suppress = true, false

local function Rescan()
    if not nameToSubclass then BuildNameMap() end
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

    wipe(skillBySubclass)
    for j = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(j)
        if not isHeader and name then
            local subclass = nameToSubclass[name]
            if subclass then
                skillBySubclass[subclass] = { rank = rank or 0, max = maxRank or 0 }
            end
        end
    end

    for j = GetNumSkillLines(), 1, -1 do
        local name, isHeader = GetSkillLineInfo(j)
        if isHeader and collapsed[name] then CollapseSkillHeader(j) end
    end

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
    if dirty then Rescan() end
    local s = skillBySubclass[subclass]
    if s then return s.rank, s.max end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    if not suppress then dirty = true end
end)
