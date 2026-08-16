-- Locale files: they must only load on their locale, and every
-- translation must keep the same format directives (%s/%d, in order) as
-- its English key - a mismatched %d crashes string.format at runtime.
local T = _G.WT_TEST
local test, assertEqual, assertTrue = T.test, T.assertEqual, T.assertTrue

local LOCALES = { "deDE", "frFR", "esES", "esMX", "ptBR", "ruRU" }

local function bootLocale(locale)
    return T.boot("Vanilla", function(m)
        m.GetLocale = function() return locale end
    end)
end

local function directives(s)
    local list = {}
    for d in tostring(s):gmatch("%%[sd]") do list[#list + 1] = d end
    return table.concat(list, " ")
end

for _, locale in ipairs(LOCALES) do
    test("locales: " .. locale .. " translations load and format-match", function()
        local B = bootLocale(locale)
        local entries = 0
        for key, value in pairs(B.ns.L) do
            entries = entries + 1
            assertTrue(value ~= key, locale .. " untranslated entry: " .. key)
            assertEqual(directives(value), directives(key),
                locale .. " format mismatch in: " .. key)
        end
        assertTrue(entries >= 13, locale .. " translation count (" .. entries .. ")")
        -- the metatable fallback still serves unknown keys as English
        assertEqual(B.ns.L["Untranslated probe"], "Untranslated probe", "fallback")
    end)
end

test("locales: enUS loads no overrides, English keys pass through", function()
    local B = bootLocale("enUS")
    local entries = 0
    for _ in pairs(B.ns.L) do entries = entries + 1 end
    assertEqual(entries, 0, "no stored entries on enUS")
    assertEqual(B.ns.L["Can be trained in: %s"], "Can be trained in: %s", "key is fallback")
end)
