-- timijshax: known trinket locations and explicitly selected spawn parts.
-- Observed locations are not a complete map of undiscovered/server-only spawns.
return function(library, utility, config, group, rawBase)
    local world = game:GetService("Workspace")
    local http = game:GetService("HttpService")
    local markers, connections = {}, {}
    local enabled, stopped = false, false
    local observed = setmetatable({}, {__mode = "k"})
    local sourceFolder
    local createMemory = loadstring(game:HttpGet(rawBase .. "DEPENDENCIES/SpawnMemory.lua", true))()
    local memory = createMemory(http, {read = readfile, write = writefile}, game.PlaceId, game.JobId, os.time)
    local container = Instance.new("Folder")
    container.Name = "TimijshaxSpawnMarkers"
    container.Parent = world
    local status = group:AddLabel("Known locations: 0", true)
    local count = 0
    local memoryStatus = group:AddLabel(memory.status, true)

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    local function remember(position, source, record)
        local key = string.format("%.0f,%.0f,%.0f", position.X, position.Y, position.Z)
        if markers[key] then
            if record then
                markers[key].record = record
                markers[key].text.Text = "[ SPAWN / " .. record.observations .. " OBS ]"
            end
            return
        end
        if count >= 3000 then return end
        local anchor = Instance.new("Part")
        anchor.Name = "SpawnMarker"
        anchor.Size = source and source.Size or Vector3.new(3, 0.25, 3)
        anchor.CFrame = source and source.CFrame or CFrame.new(position)
        anchor.Anchored = true
        anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
        anchor.Transparency = 1
        anchor.Parent = container
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = anchor
        box.Size = anchor.Size
        box.Color3 = Color3.fromRGB(83, 255, 154)
        box.Transparency = 0.65
        box.AlwaysOnTop = true
        box.ZIndex = 1
        box.Visible = enabled
        box.Parent = anchor
        local label = Instance.new("BillboardGui")
        label.Adornee = anchor
        label.Size = UDim2.fromOffset(150, 24)
        label.StudsOffset = Vector3.new(0, 2, 0)
        label.AlwaysOnTop = true
        label.Enabled = enabled
        label.Parent = anchor
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.Code
        text.TextSize = 12
        text.TextColor3 = box.Color3
        text.TextStrokeTransparency = 0.25
        text.Text = source and "[ SPAWN PART ]" or record and "[ SPAWN / " .. record.observations .. " OBS ]" or "[ KNOWN SPAWN ]"
        text.Parent = label
        markers[key] = {anchor = anchor, box = box, label = label, source = source, record = record, text = text}
        count = count + 1
        status:SetText("Known locations: " .. count)
    end

    local function save()
        memory:Save()
        memoryStatus:SetText(string.format("%d learned locations — %s", #memory.records, memory.status))
    end
    for _, record in ipairs(memory.records) do
        remember(Vector3.new(record.x, record.y, record.z), nil, record)
    end

    local function observe(object)
        if stopped or object:IsDescendantOf(container) then return end
        local part = object
        if object.Name == "ID" then part = object.Parent end
        if part and part:IsA("BasePart") and part.Parent == world
            and part.Name == "Part" and part:FindFirstChild("ID") then
            if not observed[part] then
                observed[part] = true
                local p = part.Position
                local record = memory:Observe(p.X, p.Y, p.Z)
                if record then remember(Vector3.new(record.x, record.y, record.z), nil, record) end
                memoryStatus:SetText(string.format("%d learned locations — %s", #memory.records, memory.status))
            end
        end
        if sourceFolder and object:IsA("BasePart") and object:IsDescendantOf(sourceFolder) then
            remember(object.Position, object)
        end
    end

    -- Watch first so parts arriving during the initial scan are also recorded.
    connect(world.DescendantAdded, observe)
    for _, object in ipairs(world:GetChildren()) do observe(object) end

    local function setFolder(path)
        sourceFolder = nil
        -- Changing the explicit source removes its old part markers only.
        for key, marker in pairs(markers) do
            if marker.source and not marker.record then
                marker.anchor:Destroy()
                markers[key] = nil
                count = count - 1
            end
        end
        local node = world
        for name in string.gmatch(path, "[^/]+") do
            if name ~= "Workspace" and name ~= "workspace" then
                node = node and node:FindFirstChild(name)
            end
        end
        if path ~= "" and node and node ~= world and node ~= container and not node:IsDescendantOf(container) then
            sourceFolder = node
            if node:IsA("BasePart") then remember(node.Position, node) end
            for _, part in ipairs(node:GetDescendants()) do
                if part:IsA("BasePart") then remember(part.Position, part) end
            end
        end
        status:SetText("Known locations: " .. count .. (path ~= "" and not sourceFolder and " — folder not found" or ""))
    end

    group:AddToggle("TrinketSpawnMarkers", {
        Text = "Highlight trinket spawn locations",
        Default = config.trinket_spawn_markers or false,
        Callback = function(value)
            enabled = value
            config.trinket_spawn_markers = value
            for _, marker in pairs(markers) do
                marker.box.Visible = value
                marker.label.Enabled = value
            end
        end,
    })
    enabled = config.trinket_spawn_markers or false
    group:AddLabel("Keeps observed locations marked after pickup. Unseen spawns require the map's spawn folder.", true)
    group:AddInput("TrinketSpawnFolder", {
        Text = "Spawn folder path (optional)",
        Default = config.trinket_spawn_folder or "",
        Placeholder = "Map/TrinketSpawns",
        Finished = true,
        Callback = function(value)
            config.trinket_spawn_folder = value
            setFolder(value)
        end,
    })
    group:AddButton({
        Text = "Open read-only Explorer",
        Func = function()
            local ok, err = pcall(function()
                loadstring(game:HttpGet(rawBase .. "explorer.lua", true))()
            end)
            if not ok then library:Notify("Explorer unavailable: " .. tostring(err)) end
        end,
    })
    group:AddButton({
        Text = "Save memory now",
        Func = save,
    })
    group:AddButton({
        Text = "Copy memory summary",
        Func = function()
            local lines = {"timijshax learned spawn history, place " .. tostring(game.PlaceId)}
            for _, record in ipairs(memory.records) do
                table.insert(lines, string.format("(%.1f, %.1f, %.1f) | %d observations | %d server visits | first %s | last %s",
                    record.x, record.y, record.z, record.observations, record.serverVisits,
                    record.firstSeen > 0 and os.date("!%Y-%m-%d %H:%M UTC", record.firstSeen) or "unknown",
                    record.lastSeen > 0 and os.date("!%Y-%m-%d %H:%M UTC", record.lastSeen) or "unknown"))
            end
            local report = table.concat(lines, "\n")
            print(report)
            if setclipboard then pcall(setclipboard, report) end
            library:Notify("Memory summary printed" .. (setclipboard and " and copy attempted." or "."))
        end,
    })
    group:AddButton({
        Text = "Copy spawn candidates",
        Func = function()
            local paths = {}
            for _, object in ipairs(world:GetDescendants()) do
                local name = string.lower(object.Name)
                if not object:IsDescendantOf(container) and object ~= container
                    and (string.find(name, "trinket", 1, true) or string.find(name, "spawn", 1, true) or string.find(name, "loot", 1, true))
                    and (object:IsA("Folder") or object:IsA("Model") or object:IsA("BasePart")) then
                    local segments, node = {}, object
                    while node and node ~= world do
                        table.insert(segments, 1, node.Name)
                        node = node.Parent
                    end
                    table.insert(paths, table.concat(segments, "/") .. " [" .. object.ClassName .. "]")
                end
            end
            table.sort(paths)
            local report = "timijshax spawn candidates (unverified), place " .. tostring(game.PlaceId)
                .. "\n" .. (#paths > 0 and table.concat(paths, "\n") or "No matching parts or containers replicated to this client.")
            print(report)
            if setclipboard then
                local copied = pcall(setclipboard, report)
                library:Notify(copied and "Candidate paths copied. Paste them for inspection." or "Copy failed; report printed to the console.")
            else
                library:Notify("Candidate paths printed to the console (F9).")
            end
        end,
    })
    group:AddSlider("TrinketSpawnRange", {
        Text = "Spawn marker range",
        Default = config.trinket_spawn_range or 1000,
        Min = 50, Max = 5000, Rounding = 0,
        Callback = function(value) config.trinket_spawn_range = value end,
    })
    setFolder(config.trinket_spawn_folder or "")
    local elapsed, saveElapsed = 0, 0
    connect(game:GetService("RunService").Heartbeat, function(dt)
        elapsed, saveElapsed = elapsed + dt, saveElapsed + dt
        if saveElapsed >= 15 then saveElapsed = 0; save() end
        if elapsed < 0.25 then return end
        elapsed = 0
        local camera = world.CurrentCamera
        for _, marker in pairs(markers) do
            local visible = enabled and camera ~= nil
            if visible then
                visible = (camera.CFrame.Position - marker.anchor.Position).Magnitude <= (config.trinket_spawn_range or 1000)
            end
            marker.box.Visible = visible
            marker.label.Enabled = visible
        end
    end)
    local player = game:GetService("Players").LocalPlayer
    if player then connect(player.OnTeleport, save) end
    save()
    library:OnUnload(function()
        stopped = true
        for _, connection in ipairs(connections) do connection:Disconnect() end
        save()
        container:Destroy()
    end)
end
