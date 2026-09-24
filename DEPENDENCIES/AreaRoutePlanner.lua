-- Pure coordinate grouping/order; names come from live AreaMarkers, not a fixed map.
local planner = {}
function planner.valid(p)
    if type(p) ~= "table" then return false end
    for _, k in ipairs({"x", "y", "z"}) do
        if type(p[k]) ~= "number" or p[k] ~= p[k] or math.abs(p[k]) > 1000000 then return false end
    end
    return true
end
function planner.distance(a,b) return (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2 end
function planner.area(p, markers)
    local name, best = nil, math.huge
    for _, marker in ipairs(markers) do
        if planner.valid(marker) and type(marker.name)=="string" then
            local d = planner.distance(p,marker)
            if d < best then name,best=marker.name,d end
        end
    end
    return name
end
function planner.group(records, markers)
    local groups={}
    for _, p in ipairs(records) do
        if planner.valid(p) then
            local name=planner.area(p,markers)
            if name then groups[name]=groups[name] or {}; table.insert(groups[name],p) end
        end
    end
    return groups
end
function planner.order(points, start)
    local remaining, ordered={},{}
    for _, p in ipairs(points) do if planner.valid(p) then table.insert(remaining,p) end end
    while #remaining>0 do
        local best=1
        for i=2,#remaining do
            if planner.distance(start,remaining[i]) < planner.distance(start,remaining[best]) then best=i end
        end
        start=table.remove(remaining,best);table.insert(ordered,start)
    end
    return ordered
end
return planner
