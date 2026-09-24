-- Print before network requests or waits, so execution is immediately visible.
warn("[timijshax] Recovery loader started")
local env = getgenv()
local base = env.timijshax_source or "https://raw.githubusercontent.com/sitnug/timijshax/main/"
if base:sub(-1) ~= "/" then base = base .. "/" end
-- Replace stale release pins left by earlier versions.
env.hydroxide_raw = base
local modules = {
    [1087859240] = "ROGUE/rogue_ui.lua",
    [7359098240] = "ROGUE_BATTLEGROUNDS/rlb.lua",
}
local module = modules[game.GameId]
if not module then
    error("[timijshax] Unsupported game: " .. tostring(game.GameId), 0)
end
local ok, failure = xpcall(function()
    warn("[timijshax] Downloading " .. module)
    local source = game:HttpGet(base .. module .. "?nonce=" .. tostring(math.random()), true)
    local run, compileError = loadstring(source)
    if not run then error("Module compile failed: " .. tostring(compileError), 0) end
    warn("[timijshax] Module downloaded; starting previous UI")
    run()
end, function(message) return debug.traceback(tostring(message), 2) end)
if not ok then error("[timijshax] " .. tostring(failure), 0) end
