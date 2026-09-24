-- timijshax read-only Workspace explorer. Does not modify inspected objects.
local players = game:GetService("Players")
local world = game:GetService("Workspace")
local player = players.LocalPlayer
if not player then return end
local parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("TimijshaxExplorer")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "TimijshaxExplorer"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent
local function make(class, props, into)
    local object = Instance.new(class)
    for k,v in pairs(props) do object[k] = v end
    object.Parent = into
    return object
end
local green = Color3.fromRGB(83,255,154)
local ink = Color3.fromRGB(225,245,233)
local panel = make("Frame", {
    AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.new(1,-24,1,-48), BackgroundColor3=Color3.fromRGB(8,14,12), BorderSizePixel=0,
},gui)
make("UISizeConstraint", {MaxSize=Vector2.new(800,620)},panel)
make("UIStroke", {Color=green,Thickness=1},panel)
local function text(class, value, pos, size, into)
    return make(class, {Text=value,Position=pos,Size=size,Font=Enum.Font.Code,TextSize=14,
        TextColor3=ink,BackgroundColor3=Color3.fromRGB(16,25,21),BorderSizePixel=0,
        TextTruncate=Enum.TextTruncate.AtEnd},into or panel)
end
text("TextLabel", ">_ timijshax / READ-ONLY EXPLORER",UDim2.fromOffset(8,8),UDim2.new(1,-62,0,32)).TextColor3=green
local close=text("TextButton","X",UDim2.new(1,-44,0,8),UDim2.fromOffset(36,32))
close.Activated:Connect(function() gui:Destroy() end)
local search=text("TextBox","",UDim2.fromOffset(8,48),UDim2.new(1,-16,0,36))
search.PlaceholderText="Search descendants: spawn, trinket, loot… (Enter)"
search.ClearTextOnFocus=false
search.TextXAlignment=Enum.TextXAlignment.Left
local up=text("TextButton","Up",UDim2.fromOffset(8,92),UDim2.new(0.2,-8,0,34))
local refresh=text("TextButton","Refresh",UDim2.new(0.2,4,0,92),UDim2.new(0.25,-8,0,34))
local copy=text("TextButton","Copy selected path",UDim2.new(0.45,4,0,92),UDim2.new(0.55,-12,0,34))
local location=text("TextLabel","Workspace",UDim2.fromOffset(8,132),UDim2.new(1,-16,0,28))
location.TextXAlignment=Enum.TextXAlignment.Left
local list=make("ScrollingFrame", {Position=UDim2.fromOffset(8,166),Size=UDim2.new(1,-16,1,-284),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
make("UIListLayout", {Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},list)
local details=text("TextLabel","Select a row to inspect it. Use > to open a container.",UDim2.new(0,8,1,-110),UDim2.new(1,-16,0,68))
details.TextWrapped=true
details.TextTruncate=Enum.TextTruncate.None
details.TextXAlignment=Enum.TextXAlignment.Left
local status=text("TextLabel","Only client-visible objects are available.",UDim2.new(0,8,1,-36),UDim2.new(1,-16,0,28))
status.TextSize=12
local current, selected = world, world
local function path(object)
    if object == world then return "Workspace" end
    if not object:IsDescendantOf(world) then return "[object removed]" end
    local parts={}
    while object and object ~= world do table.insert(parts,1,object.Name); object=object.Parent end
    return table.concat(parts,"/")
end
local function inspect(object)
    selected=object
    local info=path(object).." ["..object.ClassName.."]"
    if object:IsA("BasePart") then
        info=info..string.format("\nPosition: %.1f, %.1f, %.1f | Transparency: %.2f",object.Position.X,object.Position.Y,object.Position.Z,object.Transparency)
    end
    details.Text=info
end
local render
render=function()
    if current ~= world and not current:IsDescendantOf(world) then current=world end
    for _, row in ipairs(list:GetChildren()) do if row:IsA("Frame") then row:Destroy() end end
    list.CanvasPosition=Vector2.new(0,0)
    location.Text="/ "..path(current)
    local query=search.Text:lower():match("^%s*(.-)%s*$")
    local items={}
    for _, object in ipairs(query == "" and current:GetChildren() or current:GetDescendants()) do
        if object.Name ~= "TimijshaxSpawnMarkers" and not object:FindFirstAncestor("TimijshaxSpawnMarkers")
            and (query == "" or string.find(object.Name:lower(),query,1,true)) then table.insert(items,object) end
    end
    table.sort(items,function(a,b) return a.Name:lower() < b.Name:lower() end)
    for i=1,math.min(#items,200) do
        local object=items[i]
        local row=make("Frame",{Size=UDim2.new(1,-8,0,36),BackgroundTransparency=1,LayoutOrder=i},list)
        local select=text("TextButton",object.Name.." ["..object.ClassName.."]",UDim2.new(),UDim2.new(1,-42,1,0),row)
        select.TextXAlignment=Enum.TextXAlignment.Left
        select.Activated:Connect(function() inspect(object) end)
        local open=text("TextButton",">",UDim2.new(1,-36,0,0),UDim2.fromOffset(36,36),row)
        open.Activated:Connect(function() current=object; search.Text=""; inspect(object); render() end)
    end
    status.Text=#items==0 and "No matching objects. Try a different name or go Up."
        or string.format("Showing %d / %d objects. Select a row, then copy its path.",math.min(#items,200),#items)
end
search.FocusLost:Connect(function(enter) if enter then render() end end)
refresh.Activated:Connect(render)
up.Activated:Connect(function() current=current.Parent and current~=world and current.Parent or world; search.Text=""; inspect(current); render() end)
copy.Activated:Connect(function()
    local value=path(selected)
    print("[timijshax Explorer] "..value)
    local ok=setclipboard and pcall(setclipboard,value)
    status.Text=ok and "Path copied. Paste it into chat or the spawn folder setting." or "Path printed to the console (F9)."
end)
render()
