-- Headless test runner for WeaponTips. Needs Lua 5.1 / LuaJIT.
-- Run from anywhere:  luajit tests/run.lua      (paths self-locate)
-- Boots load the REAL addon files in .toc order into an isolated
-- environment and fire ADDON_LOADED + PLAYER_LOGIN - one boot per game
-- flavor (Vanilla/TBC differ only via WOW_PROJECT_ID: the TBC trainer
-- cities), plus per-test boots for class/faction/skill state.

local base = (arg[0] or ""):match("^(.-)tests[/\\]run%.lua$") or ""

local Loader = dofile(base .. "tests/loader.lua")
local buildMocks = dofile(base .. "tests/wow_mock.lua")

local FILES = {
    "Core.lua",
    "Locales/deDE.lua",
    "Locales/frFR.lua",
    "Locales/esES.lua",
    "Locales/ptBR.lua",
    "Locales/ruRU.lua",
    "Data.lua",
    "Skills.lua",
    "Tooltips.lua",
    "Options.lua",
}

-- boot("Vanilla"|"TBC", setup?) -> { ns, m, env }; setup(m) runs before
-- the files load, so tests can shape class/faction/skills/items first.
local function boot(flavor, setup)
    local m = buildMocks()
    m.WOW_PROJECT_ID = (flavor == "TBC") and 5 or 2
    local ns = {}
    local env = Loader.newEnv(m)
    if setup then setup(m) end
    Loader.loadAll(base, FILES, ns, env)
    m.Fire("ADDON_LOADED", "WeaponTips")
    m.Fire("PLAYER_LOGIN")
    return { ns = ns, m = m, env = env }
end

-- --- tiny test framework ---
local tests, currentSuite = {}, nil
local function test(name, fn) tests[#tests + 1] = { name = name, fn = fn, suite = currentSuite } end
local function fail(msg) error(msg, 3) end
local function assertEqual(got, want, msg)
    if got ~= want then
        fail((msg or "assertEqual") .. string.format(" (expected %s, got %s)", tostring(want), tostring(got)))
    end
end
local function assertTrue(c, msg) if not c then fail(msg or "assertTrue failed") end end
local function assertFalse(c, msg) if c then fail(msg or "assertFalse failed") end end

_G.WT_TEST = {
    boot = boot, test = test,
    assertEqual = assertEqual, assertTrue = assertTrue, assertFalse = assertFalse,
}

local SUITE_FILES = {
    "test_data.lua",
    "test_skills.lua",
    "test_tooltip.lua",
    "test_locales.lua",
}
for _, s in ipairs(SUITE_FILES) do
    currentSuite = s
    dofile(base .. "tests/" .. s)
end
currentSuite = nil

-- --- run ---
local passed, failed = 0, 0
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("  FAIL  [" .. t.suite .. "] " .. t.name .. "\n          " .. tostring(err))
    end
end
print(string.format("%d passed, %d failed, %d total", passed, failed, passed + failed))
os.exit(failed == 0 and 0 or 1)
