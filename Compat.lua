local _, ns = ...

-- Compat.lua: the one place that knows which client we are on.
--
-- WeaponTips runs on two API families from one codebase:
--   * Classic Era 1.15 / TBC Anniversary 2.5 - the classic globals
--     (GetSpellInfo, GetItemInfoInstant, GetSkillLineInfo, ...)
--   * WoW Forever 1.60 (Interface 160xx) - the Retail 12.x engine with
--     WOW_PROJECT_ID == WOW_PROJECT_MAINLINE. Weapon skills, the weapon
--     subclass ids, the proficiency spell ids and the city uiMapIDs are all
--     unchanged there (client DB + Blizzard UI source, build 1.60.1.69913),
--     but the classic spell / item / skill-window globals are GONE and live
--     on as C_Spell / C_SpellBook / C_Item / C_SkillInfo with table returns.
--
-- Feature files never call a spell, item or skill API directly; everything
-- goes through ns.api, so a client difference is a one-line change here.
-- The BRANCH is picked by feature (does the legacy global exist?), not by
-- flavor, and the globals are looked up at call time.

local api = {}
ns.api = api

-- read at load time so Data.lua can branch on it immediately
ns.isForever = (WOW_PROJECT_ID ~= nil and WOW_PROJECT_MAINLINE ~= nil
    and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) or false

------------------------------------------------------------------------
-- spells
------------------------------------------------------------------------

-- localized name; nil for an id whose data is not loaded (yet)
function api.GetSpellName(spellID)
    if GetSpellInfo then return (GetSpellInfo(spellID)) end
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return nil
end

-- IsSpellKnown can return false for passives like weapon proficiencies;
-- IsPlayerSpell is the reliable check. On Forever both globals only exist
-- as deprecation fallbacks (CVar loadDeprecationFallbacks), IsPlayerSpell
-- being C_SpellBook.IsSpellKnown(id, Player) - so that is the C_ twin.
function api.IsSpellKnown(spellID)
    if IsPlayerSpell then return IsPlayerSpell(spellID) and true or false end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local bank = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
        return C_SpellBook.IsSpellKnown(spellID, bank) and true or false
    end
    if IsSpellKnown then return IsSpellKnown(spellID) and true or false end
    return false
end

------------------------------------------------------------------------
-- items
------------------------------------------------------------------------

-- api.GetItemClass(item) -> classID, subClassID (item id or link). The
-- Instant variant reads the local item DB, so it never needs the server.
function api.GetItemClass(item)
    local instant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
    if not instant then return nil end
    local _, _, _, _, _, classID, subClassID = instant(item)
    return classID, subClassID
end

------------------------------------------------------------------------
-- skills
------------------------------------------------------------------------

-- true while the classic skill WINDOW api exists (index based, localized
-- names only, collapsible headers) - Skills.lua scans it on Era / TBC.
function api.HasSkillWindow()
    return (GetNumSkillLines and GetSkillLineInfo and ExpandSkillHeader
        and CollapseSkillHeader) and true or false
end

-- api.GetSkillByID(skillLineID) -> rank, maxRank; nil when the character
-- does not have the skill (or the client has no by-id lookup). Forever's
-- C_SkillInfo.GetSkillLineInfoByID is what its own paper doll reads the
-- weapon skill from: locale independent, no header juggling.
function api.HasSkillByID()
    return (C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID) and true or false
end

function api.GetSkillByID(skillLineID)
    if not (skillLineID and api.HasSkillByID()) then return nil end
    local info = C_SkillInfo.GetSkillLineInfoByID(skillLineID)
    -- a learned weapon skill starts at 1/5; anything emptier is static
    -- line data, not a skill of mine
    if not info or (info.rank or 0) <= 0 or (info.maxRank or 0) <= 0 then return nil end
    return info.rank, info.maxRank
end

------------------------------------------------------------------------
-- money
------------------------------------------------------------------------

-- copper -> "10 [silver icon]" text for a tooltip line
function api.CoinString(copper)
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(copper)
    end
    if GetMoneyString then return GetMoneyString(copper) end
    return tostring(copper)
end

-- Retail's secret values (combat) may be passed on but never compared or
-- used as a table key - check before touching a tooltip payload
function api.IsSecret(value)
    return (issecretvalue and issecretvalue(value)) and true or false
end
