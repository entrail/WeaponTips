local ADDON_NAME, ns = ...
local L = ns.L

-- Settings under Settings -> Options -> AddOns using the modern Settings
-- API, same pattern as PetTips/ProfessionTips. Changes apply immediately.

ns.OnInit(function()
    local category, layout = Settings.RegisterVerticalLayoutCategory(ADDON_NAME)
    category.ID = ADDON_NAME
    ns.settingsCategory = category

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["Weapon Tooltips"]))

    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "WeaponTips_ShowUsable",
            "showUsable",
            ns.db,
            Settings.VarType.Boolean,
            L["Show usable weapons"],
            true
        )
        Settings.CreateCheckbox(category, setting,
            L["Green line when you already have the weapon skill, including your current and maximum skill level."])
    end

    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "WeaponTips_ShowTrainable",
            "showTrainable",
            ns.db,
            Settings.VarType.Boolean,
            L["Show trainable weapons"],
            true
        )
        Settings.CreateCheckbox(category, setting,
            L["Yellow line when your class can learn this weapon type but has not yet, listing the cities with a weapon master that teaches it."])
    end

    do
        local setting = Settings.RegisterAddOnSetting(
            category,
            "WeaponTips_ShowUnusable",
            "showUnusable",
            ns.db,
            Settings.VarType.Boolean,
            L["Show unusable weapons"],
            true
        )
        Settings.CreateCheckbox(category, setting,
            L["Red line when your class can never use this weapon type."])
    end

    Settings.RegisterAddOnCategory(category)
end)

SLASH_WEAPONTIPS1 = "/weapontips"
SlashCmdList.WEAPONTIPS = function()
    Settings.OpenToCategory(ADDON_NAME)
end
