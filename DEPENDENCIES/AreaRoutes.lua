-- Learned, local area routes. Walkable paths are computed on the current map.
return function(library, group, adapter, rawBase)
    local http=game:GetService("HttpService")
    local world=game:GetService("Workspace")
    local player=game:GetService("Players").LocalPlayer
    local paths=game:GetService("PathfindingService")
    local planner=loadstring(game:HttpGet(rawBase.."DEPENDENCIES/AreaRoutePlanner.lua",true))()
    local groups, markers, mappings = {}, {}, {}
    local area, gateName, useGate, repeatDelay = nil, "", false, 60
    local running, worker, preview, previewArea, gateTimer = false, nil, nil, nil, nil
    local gateOwned=false
    local filename="timijshax-area-gates-"..game.PlaceId..".json"
    local status=group:AddLabel("Refresh learned spots to begin.",true)
    local mappingStatus=group:AddLabel("No Gate mapping selected",true)
    if readfile then
        local ok,data=pcall(function() return http:JSONDecode(readfile(filename)) end)
        if ok and type(data)=="table" and data.placeId==game.PlaceId and type(data.mappings)=="table" then
            for name,m in pairs(data.mappings) do
                if type(name)=="string" and type(m)=="table" and planner.valid(m.position) and type(m.gate)=="string" and #m.gate>0 and #m.gate<=80 then mappings[name]=m end
            end
        end
    end
    local function point(v) return {x=v.X,y=v.Y,z=v.Z} end
    local function vector(p) return Vector3.new(p.x,p.y,p.z) end
    local function character()
        local c=player.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if not h or h.Health<=0 or not r then error("Character unavailable; wait for respawn.",0) end
        return c,h,r
    end
    local function mapped()
        local m=area and mappings[area]
        mappingStatus:SetText(m and ("Gate mapping: "..m.gate) or "No Gate mapping selected")
    end
    local function cleanup()
        running=false;adapter.setBusy(false)
        if gateTimer then pcall(task.cancel,gateTimer);gateTimer=nil end
        if gateOwned then adapter.releaseGate();gateOwned=false end
        local c=player.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if h and r then h:MoveTo(r.Position) end
    end
    local function stop()
        if worker then pcall(task.cancel,worker);worker=nil end
        cleanup();status:SetText("Stopped")
    end
    local function invalidate() preview=nil;previewArea=nil end
    local dropdown=group:AddDropdown("LearnedRouteArea",{Text="Area",Values={},AllowNull=true,Searchable=true,
        Callback=function(value) area=value;invalidate();mapped() end})
    local function refresh()
        if running then library:Notify("Stop the area route before refreshing.");return end
        markers={}
        local folder=world:FindFirstChild("AreaMarkers")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("BasePart") then local p=point(m.Position);p.name=m.Name;table.insert(markers,p) end
            end
        end
        local memory=library.TimijshaxSpawnMemory
        groups=planner.group(memory and memory.records or {},markers)
        local names={};for name in pairs(groups) do table.insert(names,name) end;table.sort(names)
        dropdown:SetValues(names)
        if not area or not groups[area] then dropdown:SetValue(names[1]) end
        invalidate();mapped()
        status:SetText(#markers==0 and "No AreaMarkers available on this map." or #names==0 and "No learned spots yet. Explore with spawn memory active." or tostring(#names).." areas with learned spots. Assignment uses nearest marker.")
    end
    group:AddButton({Text="Refresh learned areas",Func=refresh})
    group:AddToggle("AreaRouteUseGate",{Text="Gate before route",Default=false,Callback=function(v) useGate=v;invalidate() end})
    group:AddInput("AreaRouteGateName",{Text="Gate destination",Default="",Placeholder="Exact destination, e.g. Tundra 7",Finished=false,Callback=function(v) gateName=tostring(v):sub(1,80) end})
    group:AddButton({Text="Record Gate arrival here",Func=function()
        if running then library:Notify("Stop the area route first.");return end
        if not area or gateName:match("^%s*$") then library:Notify("Select an area and enter its exact Gate destination first.");return end
        local ok,err=pcall(function()
            local _,_,r=character()
            mappings[area]={gate=gateName,position=point(r.Position)};invalidate();mapped()
            if writefile then
                writefile(filename,http:JSONEncode({version=1,placeId=game.PlaceId,mappings=mappings}))
                status:SetText("Gate arrival saved locally for "..area)
            else status:SetText("Gate arrival recorded for this session only.") end
        end)
        if not ok then library:Notify("Arrival retained in session if recorded; save failed: "..tostring(err)) end
    end})
    group:AddLabel("After gating manually, record the arrival here. Area names may differ from Gate destinations.",true)
    local function ground(p)
        local c=player.Character
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances=c and {c} or {}
        local hit=world:Raycast(vector(p)+Vector3.new(0,6,0),Vector3.new(0,-40,0),params)
        return hit and hit.Position+Vector3.new(0,3,0) or nil
    end
    local function build(start, selected)
        local spots=groups[selected]
        if not spots or #spots==0 then error("No learned spots in this area. Refresh first.",0) end
        if #spots>100 then error("Area has over 100 spots; split it into a recorded custom route.",0) end
        local route,skipped,visited={},0,0
        local cursor=start
        for i,p in ipairs(planner.order(spots,point(start))) do
            if not running then return nil end
            status:SetText(string.format("Planning %d/%d spots...",i,#spots))
            local target=ground(p)
            local ok,path=pcall(function()
                if not target then return nil end
                local candidate=paths:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
                candidate:ComputeAsync(cursor,target)
                return candidate
            end)
            if ok and path and path.Status==Enum.PathStatus.Success then
                local waypoints=path:GetWaypoints()
                if #waypoints>0 then
                    for _, w in ipairs(waypoints) do table.insert(route,{position=w.Position,jump=w.Action==Enum.PathWaypointAction.Jump}) end
                    route[#route].loot=true;cursor=waypoints[#waypoints].Position;visited=visited+1
                else skipped=skipped+1 end
                path:Destroy()
            else
                if ok and path then path:Destroy() end
                skipped=skipped+1
            end
            if #route>2000 then error("Generated route exceeds 2000 waypoints.",0) end
        end
        if visited==0 then error("No reachable spots found from the starting position.",0) end
        return {points=route,visited=visited,skipped=skipped,start=start}
    end
    local function launch(fn)
        if running or adapter.busy() then library:Notify("Another route is active. Stop it first.");return end
        running=true;adapter.setBusy(true)
        worker=task.defer(function()
            local ok,err=pcall(fn)
            worker=nil;cleanup()
            if not ok then status:SetText("Stopped: "..tostring(err));warn("[timijshax] Area route:",err) end
        end)
    end
    group:AddButton({Text="Generate route preview",Func=function()
        local selected=area
        launch(function()
            local _,_,r=character()
            local start=r.Position
            if useGate then
                local m=selected and mappings[selected];if not m then error("Record a Gate arrival for this area first.",0) end
                start=vector(m.position)
            elseif planner.area(point(start),markers)~=selected then error("Enter the selected area or enable its mapped Gate first.",0) end
            preview=build(start,selected);previewArea=selected
            if preview then
                adapter.preview(preview.points)
                status:SetText(string.format("Preview: %d spots, %d skipped, %d waypoints. Ready to run.",preview.visited,preview.skipped,#preview.points))
            end
        end)
    end})
    local function walk(route)
        local initial=player.Character
        for i,w in ipairs(route.points) do
            if not running then return end
            if player.Character~=initial then error("Character changed; route stopped.",0) end
            local _,h,r=character()
            status:SetText(string.format("Moving %d/%d",i,#route.points))
            if w.jump then h.Jump=true end
            h:MoveTo(w.position)
            local deadline=os.clock()+8
            repeat
                task.wait(0.1)
                if player.Character~=initial or h.Health<=0 then error("Character lost; route stopped.",0) end
                if os.clock()>deadline then error("Movement blocked. Generate a fresh route.",0) end
            until not running or (r.Position-w.position).Magnitude<=4
            if running and w.loot then
                for _, object in ipairs(world:GetChildren()) do
                    if object:IsA("BasePart") and object.Name=="Part" and object:FindFirstChild("ID") and (object.Position-r.Position).Magnitude<=12 then
                        local click=object:FindFirstChildWhichIsA("ClickDetector",true)
                        if click and (object.Position-r.Position).Magnitude<=click.MaxActivationDistance then
                            fireclickdetector(click)
                        end
                    end
                end
                task.wait(0.3)
            end
        end
    end
    local function run(loop)
        if not preview or previewArea~=area then library:Notify("Generate a preview for the selected area first.");return end
        if not fireclickdetector then library:Notify("This executor cannot activate trinket ClickDetectors.");return end
        local selected, route, mapping, gating=area,preview,area and mappings[area],useGate
        launch(function()
            if gating then
                gateOwned=true
                status:SetText("Gating to "..mapping.gate.."...")
                gateTimer=task.delay(45,function() gateTimer=nil;stop();status:SetText("Gate timed out; stopped.") end)
                local ok=adapter.gate(mapping.gate,vector(mapping.position))
                task.cancel(gateTimer);gateTimer=nil;adapter.releaseGate();gateOwned=false
                local _,_,r=character()
                if not ok or (r.Position-vector(mapping.position)).Magnitude>50 then error("Gate arrival could not be verified; stopped.",0) end
                -- Replan from the actual arrival, including any landing offset.
                route=build(r.Position,selected)
            else
                local _,_,r=character()
                if (r.Position-route.start).Magnitude>10 then error("You moved since preview. Generate a fresh preview.",0) end
            end
            repeat
                walk(route)
                if not loop or not running then break end
                local deadline=os.clock()+repeatDelay
                while running and os.clock()<deadline do
                    status:SetText(string.format("Repeat in %ds",math.ceil(deadline-os.clock())));task.wait(0.5)
                end
                if running then local _,_,r=character();route=build(r.Position,selected) end
            until not running
            status:SetText(loop and "Stopped" or string.format("Finished once: visited %d spots; %d skipped.",route.visited,route.skipped))
        end)
    end
    group:AddSlider("AreaRouteRepeatDelay",{Text="Repeat delay (seconds)",Default=60,Min=10,Max=600,Rounding=0,Callback=function(v) repeatDelay=v end})
    group:AddButton({Text="Run area once",Func=function() run(false) end})
    group:AddButton({Text="Repeat area route",Func=function() run(true) end})
    group:AddButton({Text="Stop area route",Func=stop})
    group:AddLabel("Uses learned spots and walking paths. Unreachable spots are skipped. Preview replaces the displayed custom route.",true)
    library:OnUnload(stop)
    refresh()
    return stop
end
