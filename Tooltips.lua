local ADDON_NAME, ns = ...
local L = ns.L

-- One extra line on every weapon tooltip:
--   green  - you have the weapon skill (with current/max rank)
--   yellow - your class can learn it, listing the weapon master cities
--            of your faction (or the shaman talent hint)
--   red    - your class can never use this weapon type

local ITEM_CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2

local function CityList(subclass)
    local byFaction = ns.TRAINERS[subclass]
    local list = byFaction and ns.playerFaction and byFaction[ns.playerFaction]
    if not list or #list == 0 then return nil end
    local names = {}
    for i, city in ipairs(list) do
        local info = C_Map.GetMapInfo(city.map)
        names[i] = (info and info.name) or city.name
    end
    return table.concat(names, ", ")
end

local function AddWeaponLines(tooltip, item)
    if not (ns.db and ns.playerClass) then return end
    if ns.api.IsSecret(item) then return end -- Forever: hidden in combat
    local classID, subClassID = ns.api.GetItemClass(item)
    if classID ~= ITEM_CLASS_WEAPON then return end
    if not ns.PROF_SPELL[subClassID] then return end -- fishing poles etc.

    local rank, max = ns.GetWeaponSkill(subClassID)
    if rank then
        if ns.db.showUsable then
            tooltip:AddLine(string.format(L["You can use this weapon (%d/%d)."], rank, max),
                0.4, 0.9, 0.4)
        end
        return
    end
    -- Proficiency known but no skill line resolved (locale mismatch):
    -- still green, just without the rank numbers - never a false yellow.
    if ns.IsWeaponSkillKnown(subClassID) then
        if ns.db.showUsable then
            tooltip:AddLine(L["You can use this weapon."], 0.4, 0.9, 0.4)
        end
        return
    end

    local usable = ns.CLASS_WEAPONS[ns.playerClass]
    if usable and usable[subClassID] then
        if not ns.db.showTrainable then return end
        local talentOnly = ns.TALENT_WEAPONS[ns.playerClass]
        if talentOnly and talentOnly[subClassID] then
            tooltip:AddLine(L["Requires the shaman talent 'Two-Handed Axes and Maces'."],
                1, 0.82, 0, true)
        else
            local cityText = CityList(subClassID)
            if cityText then
                tooltip:AddLine(string.format(L["Can be trained in: %s"], cityText),
                    1, 0.82, 0, true)
                local cost = ns.TRAIN_COST[subClassID] or ns.TRAIN_COST_DEFAULT
                local costText = ns.api.CoinString(cost)
                local reqLevel = ns.TRAIN_LEVEL[subClassID]
                if reqLevel then
                    tooltip:AddLine(string.format(L["Training cost: %s (from level %d)"],
                        costText, reqLevel), 1, 0.82, 0)
                else
                    tooltip:AddLine(string.format(L["Training cost: %s"], costText),
                        1, 0.82, 0)
                end
            end
        end
    elseif ns.db.showUnusable then
        tooltip:AddLine(L["Your class cannot use this type of weapon."],
            1, 0.35, 0.35)
    end
end

ns.OnLogin(function()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        -- Modern tooltip system (Classic Era 1.15+, TBC Anniversary 2.5.5+)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip
                and tooltip ~= ShoppingTooltip1 and tooltip ~= ShoppingTooltip2 then
                return
            end
            local itemID = data and data.id
            if ns.api.IsSecret(itemID) then return end -- even `not x` throws on one
            if not itemID and TooltipUtil and TooltipUtil.GetDisplayedItem then
                local _, link = TooltipUtil.GetDisplayedItem(tooltip)
                if link then itemID = link end
            end
            if itemID then AddWeaponLines(tooltip, itemID) end
        end)
    else
        -- Legacy fallback, in case a flavor still uses OnTooltipSetItem
        local function HookTip(tip)
            if not tip then return end
            tip:HookScript("OnTooltipSetItem", function(self)
                local _, link = self:GetItem()
                if link then AddWeaponLines(self, link) end
            end)
        end
        HookTip(GameTooltip)
        HookTip(ItemRefTooltip)
        HookTip(ShoppingTooltip1)
        HookTip(ShoppingTooltip2)
    end
end)
