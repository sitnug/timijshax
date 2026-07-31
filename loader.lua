local DEFAULT_REPO = getgenv().hydroxide_repo or "zyu/hydroxide"
local gameId = game.GameId
if gameId == 1087859240 then
    pcall(function()
        loadstring(game:HttpGet(
            "https://git.fable.bz/".. DEFAULT_REPO .."/raw/branch/main/ROGUE/rogue_ui.lua?nonce="..tostring(math.random()),
            true
        ))()
    end)
elseif gameId == 7359098240 then
    pcall(function()
        loadstring(game:HttpGet(
            "https://git.fable.bz/".. DEFAULT_REPO .."/raw/branch/main/ROGUE_BATTLEGROUNDS/rlb.lua?nonce="..tostring(math.random()),
            true
        ))()
    end)
end
