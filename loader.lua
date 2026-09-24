if not game:IsLoaded() then game.Loaded:Wait() end
local env = getgenv()
local RELEASE_RAW = "https://raw.githubusercontent.com/sitnug/timijshax/cfa647e25d973629587f53b11dfaaf821e4667ad/"
-- Refresh old official release pins; preserve an explicitly configured custom source.
local custom = env.timijshax_source or env.hydroxide_raw
if type(custom) ~= "string" or custom:find("https://raw.githubusercontent.com/sitnug/timijshax/", 1, true) == 1 then
    custom = nil
end
local DEFAULT_RAW = custom or RELEASE_RAW
if DEFAULT_RAW:sub(-1) ~= "/" then DEFAULT_RAW = DEFAULT_RAW .. "/" end
env.hydroxide_raw = DEFAULT_RAW

-- Play asynchronously so audio download/support never delays the game module.
task.spawn(function()
    local sound
    local ok, err = pcall(function()
        local asset = getcustomasset or getsynasset
        if not asset or not writefile then return end
        local path = "timijshax-activated-v1.mp3"
        if not isfile or not isfile(path) then
            writefile(path, game:HttpGet(DEFAULT_RAW .. "ASSETS/activated.mp3", true))
        end
        local soundService = game:GetService("SoundService")
        local previous = soundService:FindFirstChild("TimijshaxActivation")
        if previous then previous:Destroy() end
        sound = Instance.new("Sound")
        sound.Name = "TimijshaxActivation"
        sound.SoundId = asset(path)
        sound.Volume = 0.7
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

local modules = {
    [1087859240] = "ROGUE/rogue_ui.lua",
    [7359098240] = "ROGUE_BATTLEGROUNDS/rlb.lua",
}
local path = modules[game.GameId]
if not path then
    error("[timijshax] Unsupported game. Join Rogue Lineage or Rogue Lineage Battlegrounds first. GameId=" .. tostring(game.GameId), 0)
end
print("[timijshax] Downloading " .. path .. (env.timijshax_classic_ui and " (classic UI recovery)" or " (command UI)"))
local downloaded, source = pcall(function()
    return game:HttpGet(DEFAULT_RAW .. path .. "?nonce=" .. tostring(math.random()), true)
end)
if not downloaded then error("[timijshax] Download failed: " .. tostring(source), 0) end
local run, compileError = loadstring(source, "@timijshax/" .. path)
if not run then error("[timijshax] Compile failed: " .. tostring(compileError), 0) end
print("[timijshax] Starting module. Any startup error will appear below.")
local started, startupError = xpcall(run, function(err) return debug.traceback(tostring(err), 2) end)
if not started then error("[timijshax] Startup failed: " .. tostring(startupError), 0) end
