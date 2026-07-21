local ADDON_NAME, ns = ...

ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

-- Localization: all user-facing text goes through ns.L["English text"].
-- English is the key and the fallback; locale files can override entries.
ns.L = setmetatable({}, { __index = function(_, key) return key end })

-- One codebase for Classic Era (1.15) and TBC Anniversary (2.5.5); the
-- only data difference is the two extra TBC capitals (Silvermoon, Exodar).
ns.isTBC = WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)

-- Account-wide settings: behavior should be identical on every character.
local defaults = {
    showUsable = true,     -- green line: skill known, with current level
    showTrainable = true,  -- yellow line: learnable, lists trainer cities
    showUnusable = true,   -- red line: class can never use this type
}

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- ns.OnInit(fn) -> runs at ADDON_LOADED, after ns.db is ready.
-- ns.OnLogin(fn) -> runs at PLAYER_LOGIN, when player info is reliable.
local initCallbacks, loginCallbacks = {}, {}
function ns.OnInit(fn) table.insert(initCallbacks, fn) end
function ns.OnLogin(fn) table.insert(loginCallbacks, fn) end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        WeaponTipsDB = WeaponTipsDB or {}
        CopyDefaults(defaults, WeaponTipsDB)
        ns.db = WeaponTipsDB
        for _, fn in ipairs(initCallbacks) do fn() end
    elseif event == "PLAYER_LOGIN" then
        ns.playerClass = select(2, UnitClass("player"))
        ns.playerFaction = UnitFactionGroup("player")
        for _, fn in ipairs(loginCallbacks) do fn() end
    end
end)
