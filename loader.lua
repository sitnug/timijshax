local DEFAULT_RAW = getgenv().hydroxide_raw or "https://raw.githubusercontent.com/sitnug/timijshax/main/"

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

local gameId = game.GameId
if gameId == 1087859240 then
    pcall(function()
        loadstring(game:HttpGet(
            DEFAULT_RAW .. "ROGUE/rogue_ui.lua?nonce="..tostring(math.random()),
            true
        ))()
    end)
elseif gameId == 7359098240 then
    pcall(function()
        loadstring(game:HttpGet(
            DEFAULT_RAW .. "ROGUE_BATTLEGROUNDS/rlb.lua?nonce="..tostring(math.random()),
            true
        ))()
    end)
end
