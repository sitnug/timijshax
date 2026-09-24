-- Print before network requests or waits, so execution is immediately visible.
warn("[timijshax] Loader started")
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
-- Play asynchronously so audio download/support never delays the game module.
task.spawn(function()
    local sound
    local ok, err = pcall(function()
        local asset = getcustomasset or getsynasset
        if not asset or not writefile then
            warn("[timijshax] Voice unavailable: executor needs writefile and getcustomasset/getsynasset")
            return
        end
        local path = "timijshax-activated-v2.mp3"
        if not isfile or not isfile(path) then
            writefile(path, game:HttpGet(base .. "ASSETS/activated.mp3", true))
        end
        local soundService = game:GetService("SoundService")
        local previous = soundService:FindFirstChild("TimijshaxActivation")
        if previous then previous:Destroy() end
        sound = Instance.new("Sound")
        sound.Name = "TimijshaxActivation"
        sound.SoundId = asset(path)
        sound.Volume = 5
        sound.Parent = soundService
        sound.Ended:Once(function() sound:Destroy() end)
        game:GetService("Debris"):AddItem(sound, 15)
        sound:Play()
    end)
    if not ok then
        if sound then sound:Destroy() end
        warn("[timijshax] Activation audio unavailable:", err)
    end
end)

local ok, failure = xpcall(function()
    warn("[timijshax] Downloading " .. module)
    local source = game:HttpGet(base .. module .. "?nonce=" .. tostring(math.random()), true)
    local run, compileError = loadstring(source)
    if not run then error("Module compile failed: " .. tostring(compileError), 0) end
    warn("[timijshax] Module downloaded; starting module")
    run()
end, function(message) return debug.traceback(tostring(message), 2) end)
if not ok then error("[timijshax] " .. tostring(failure), 0) end
