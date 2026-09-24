-- Local position inspection and explicit waypoint export. No uploads.
return function(library, group)
    local player = game:GetService("Players").LocalPlayer
    local http = game:GetService("HttpService")
    local enabled, elapsed, label = false, 0, ""
    local points = {}
    local status = group:AddLabel("Position debug off", true)
    local count = group:AddLabel("0 waypoints captured (this session)", true)
    local hud = Instance.new("TextLabel")
    hud.Name = "TimijshaxPositionDebug"
    hud.AnchorPoint = Vector2.new(0, 1)
    hud.Position = UDim2.new(0, 16, 1, -48)
    hud.Size = UDim2.new(0, 320, 0, 66)
    hud.BackgroundColor3 = Color3.fromRGB(18, 22, 20)
    hud.BackgroundTransparency = 0.15
    hud.TextColor3 = Color3.fromRGB(170, 255, 100)
    hud.Font = Enum.Font.Code
    hud.TextSize = 14
    hud.TextWrapped = true
    hud.Visible = false
    hud.Parent = library.ScreenGui

    local function position()
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return nil end
        local p = root.Position
        -- Reject invalid positions rather than exporting unusable route data.
        for _, value in ipairs({p.X, p.Y, p.Z}) do
            if value ~= value or math.abs(value) == math.huge then return nil end
        end
        return {x=p.X, y=p.Y, z=p.Z, label=label}
    end
    local function update()
        if not enabled then return end
        local p = position()
        local text = p and string.format("X %.2f   Y %.2f   Z %.2f", p.x, p.y, p.z) or "Waiting for character..."
        status:SetText(text)
        hud.Text = "TIMIJSHAX / POSITION DEBUG\n" .. text .. "\nPlace " .. tostring(game.PlaceId)
    end
    local function copy(data)
        local text = http:JSONEncode(data)
        local ok = setclipboard and pcall(setclipboard, text)
        if ok then
            library:Notify("Coordinates copied. Paste them to share.")
        else
            print("[timijshax] Position export: " .. text)
            library:Notify("Clipboard unavailable; coordinates printed to F9 console.")
        end
    end
    local function capture()
        local p = position()
        if not p then library:Notify("Character position unavailable; wait for respawn.") end
        return p
    end
    group:AddToggle("TimijshaxPositionDebug", {
        Text="Position debug overlay", Default=false,
        Callback=function(value)
            enabled = value
            hud.Visible = value
            if value then update() else status:SetText("Position debug off") end
        end,
    })
    group:AddInput("TimijshaxWaypointLabel", {
        Text="Waypoint name", Default="", Placeholder="e.g. cave entrance", Finished=false,
        Callback=function(value) label = tostring(value):sub(1, 80) end,
    })
    group:AddButton({Text="Copy current position", Func=function()
        local p = capture()
        if p then copy({version=1, placeId=game.PlaceId, points={p}}) end
    end})
    group:AddButton({Text="Capture waypoint", Func=function()
        if #points >= 200 then library:Notify("200 waypoint limit. Copy this route before starting another session."); return end
        local p = capture()
        if not p then return end
        if p.label == "" then p.label = "Point " .. tostring(#points + 1) end
        table.insert(points, p)
        count:SetText(tostring(#points) .. " waypoints captured (this session)")
        library:Notify("Captured " .. p.label)
    end})
    group:AddButton({Text="Undo last waypoint", Func=function()
        table.remove(points)
        count:SetText(tostring(#points) .. " waypoints captured (this session)")
    end})
    group:AddButton({Text="Copy waypoint list", Func=function()
        if #points == 0 then library:Notify("Capture a waypoint first."); return end
        copy({version=1, placeId=game.PlaceId, points=points})
    end})
    group:AddLabel("Copy your waypoints before leaving. Captures are session-only.", true)
    local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not enabled then return end
        elapsed = elapsed + dt
        if elapsed < 0.2 then return end
        elapsed = 0
        update()
    end)
    library:OnUnload(function()
        connection:Disconnect()
        hud:Destroy()
    end)
end
