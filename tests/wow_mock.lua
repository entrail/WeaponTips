-- Minimal-but-live WoW API mock set for headless WeaponTips tests (same
-- architecture as ../PetTips/tests/wow_mock.lua: frames KEEP their
-- events/scripts/hooks so tests drive the addon through the same paths
-- the game uses). Returns a builder; every boot is isolated.
--
-- WeaponTips-specific pieces:
--   * tooltips record AddLine COLORS (the addon's whole output is color)
--   * a collapsible skill-line tree behind GetSkillLineInfo /
--     Expand/CollapseSkillHeader, which fire SKILL_LINES_CHANGED
--     synchronously like the client - exercising the scan's expand,
--     restore and event-suppression logic for real
--   * GetItemInfoInstant backed by M.state.items
--   * C_Timer.After queues into M.__timers; M.RunTimers() flushes

local M

local frameMethods = {}
function frameMethods.RegisterEvent(self, e) self.__events[e] = true end
function frameMethods.UnregisterEvent(self, e) self.__events[e] = nil end
function frameMethods.UnregisterAllEvents(self) self.__events = {} end
function frameMethods.SetScript(self, k, fn) self.__scripts[k] = fn end
function frameMethods.GetScript(self, k) return self.__scripts[k] end
function frameMethods.HookScript(self, k, fn)
    self.__hooks[k] = self.__hooks[k] or {}
    table.insert(self.__hooks[k], fn)
end

local function newFrame(name, parent)
    local f = {
        __name = name, __parent = parent, __shown = true,
        __events = {}, __scripts = {}, __hooks = {},
    }
    setmetatable(f, { __index = function(_, k)
        local m = frameMethods[k]
        if m then return m end
        if type(k) == "string" and k:match("^%u") then return function() end end
        return nil
    end })
    table.insert(M.__frames, f)
    return f
end

return function()
    M = { __frames = {}, __timers = {}, __prints = {} }

    -- ------------------------------------------------------ game state
    M.state = {
        class = "WARRIOR",
        faction = "Alliance",
        -- authored skill window: { header = "..."/nil, expanded = bool }
        -- entries followed by their { name=, rank=, max= } lines
        skills = {},
        -- itemId -> { classID=, subClassID= }
        items = {},
        -- uiMapID -> localized name (nil -> C_Map returns nil, the addon
        -- falls back to the English names shipped in Data.lua)
        mapNames = {},
    }

    -- ------------------------------------------------------ dispatch
    function M.Fire(event, ...)
        local snapshot = {}
        for i, f in ipairs(M.__frames) do snapshot[i] = f end
        for _, f in ipairs(snapshot) do
            if f.__events[event] and f.__scripts.OnEvent then
                f.__scripts.OnEvent(f, event, ...)
            end
        end
    end
    function M.FireHooks(frame, script, ...)
        for _, fn in ipairs(frame.__hooks[script] or {}) do fn(...) end
    end

    -- ------------------------------------------------------ frames / UI
    M.CreateFrame = function(_, name, parent)
        local f = newFrame(name, parent)
        if name then M.__env[name] = f end
        return f
    end
    M.UIParent = newFrame("UIParent")

    -- tooltip: records AddLine as { left=, r=, g=, b= }
    local function newTooltip(name)
        local tip = newFrame(name)
        tip.__lines = {}
        tip.__item = nil
        tip.AddLine = function(self, text, r, g, b)
            table.insert(self.__lines, { left = tostring(text), r = r, g = g, b = b })
        end
        tip.NumLines = function(self) return #self.__lines end
        tip.GetItem = function(self)
            if self.__item then return self.__item[1], self.__item[2] end
        end
        return tip
    end
    M.GameTooltip = newTooltip("GameTooltip")
    M.ItemRefTooltip = newTooltip("ItemRefTooltip")
    M.ShoppingTooltip1 = newTooltip("ShoppingTooltip1")
    M.ShoppingTooltip2 = newTooltip("ShoppingTooltip2")

    -- hover an item like the game: fresh lines, then OnTooltipSetItem hooks
    function M.HoverItem(itemId, tip)
        tip = tip or M.GameTooltip
        tip.__lines = {}
        tip.__item = { "Item" .. itemId, "item:" .. itemId }
        M.FireHooks(tip, "OnTooltipSetItem", tip)
        return tip.__lines
    end

    -- all rendered text of the last hover in one string, for find() asserts
    function M.TooltipText(tip)
        tip = tip or M.GameTooltip
        local parts = {}
        for _, l in ipairs(tip.__lines) do parts[#parts + 1] = l.left end
        return table.concat(parts, "\n")
    end

    -- ------------------------------------------------------ skill window
    -- Visible rows = headers always, lines only under an expanded header
    -- (lines before any header are always visible), like the real client.
    local function visibleSkills()
        local rows, show = {}, true
        for _, node in ipairs(M.state.skills) do
            if node.header then
                rows[#rows + 1] = node
                show = node.expanded
            elseif show then
                rows[#rows + 1] = node
            end
        end
        return rows
    end
    M.GetNumSkillLines = function() return #visibleSkills() end
    M.GetSkillLineInfo = function(i)
        local node = visibleSkills()[i]
        if not node then return nil end
        if node.header then
            return node.header, true, node.expanded, 1, 0, 0, 1
        end
        return node.name, false, false, node.rank, 0, 0, node.max
    end
    local function setExpanded(i, expanded)
        local node = visibleSkills()[i]
        if node and node.header then
            node.expanded = expanded
            M.Fire("SKILL_LINES_CHANGED") -- the client fires this too
        end
    end
    M.ExpandSkillHeader = function(i) setExpanded(i, true) end
    M.CollapseSkillHeader = function(i) setExpanded(i, false) end

    -- ------------------------------------------------------ player / items
    M.UnitClass = function() return "Localized", M.state.class end
    M.UnitFactionGroup = function() return M.state.faction end
    M.GetItemInfoInstant = function(item)
        local id = tonumber(item) or tonumber(tostring(item):match("item:(%d+)"))
        local it = id and M.state.items[id]
        if not it then return nil end
        return id, "Weapon", "Sub", it.equipLoc or "", 134400, it.classID, it.subClassID
    end
    M.C_Map = {
        GetMapInfo = function(mapId)
            local name = M.state.mapNames[mapId]
            if name then return { mapID = mapId, name = name } end
            return nil
        end,
    }

    -- deterministic fake names: proficiency spell 201 -> "Spell201"
    M.GetSpellInfo = function(id) return "Spell" .. id, nil, "icon" .. id end
    M.GetCoinTextureString = function(copper) return tostring(copper) .. "c" end

    -- ------------------------------------------------------ flavor
    M.WOW_PROJECT_CLASSIC = 2
    M.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
    M.WOW_PROJECT_ID = 2

    -- ------------------------------------------------------ misc API
    M.Enum = { ItemClass = { Weapon = 2 } }
    M.C_AddOns = { GetAddOnMetadata = function() return "test" end }
    M.GetLocale = function() return "enUS" end
    M.C_Timer = { After = function(_, fn) table.insert(M.__timers, fn) end }
    function M.RunTimers()
        local t = M.__timers
        M.__timers = {}
        for _, fn in ipairs(t) do fn() end
    end
    M.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    M.strtrim = function(s) return (tostring(s):gsub("^%s*(.-)%s*$", "%1")) end
    M.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
        table.insert(M.__prints, table.concat(parts, " "))
    end
    M.SlashCmdList = {}

    -- ------------------------------------------------------ Settings API
    local function stubInitializer()
        return setmetatable({}, { __index = function(_, k)
            if type(k) == "string" and k:match("^%u") then return function() end end
            return nil
        end })
    end
    M.Settings = {
        RegisterVerticalLayoutCategory = function()
            return {}, { AddInitializer = function() end }
        end,
        RegisterAddOnSetting = function() return {} end,
        SetOnValueChangedCallback = function() end,
        CreateCheckbox = function() return stubInitializer() end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function() end,
        VarType = { Boolean = "boolean", Number = "number", String = "string" },
    }
    M.CreateSettingsListSectionHeaderInitializer = function() return {} end

    return M
end
