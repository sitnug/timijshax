-- Run with: luau TESTS/spawn_memory.luau
local createMemory = require("../DEPENDENCIES/SpawnMemory")
local files, encoded, serial = {}, {}, 0
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = clone(item) end
    return result
end
local http = {}
function http:JSONEncode(data)
    serial += 1
    local raw = "snapshot-" .. serial
    encoded[raw] = clone(data)
    return raw
end
function http:JSONDecode(raw)
    assert(encoded[raw], "corrupt JSON")
    return clone(encoded[raw])
end
local store = {
    read = function(path) assert(files[path], "missing"); return files[path] end,
    write = function(path, value) files[path] = value end,
}
local now = 100
local function clock() return now end
local path = "timijshax-spawns-123.json"
files[path] = http:JSONEncode({{1,2,3}, {"bad",2,3}})
local memory = createMemory(http, store, 123, "server-a", clock)
assert(#memory.records == 1 and memory.records[1].observations == 0, "legacy migration")
local point = memory:Observe(1.1,2,3)
assert(#memory.records == 1 and point.observations == 1 and point.firstSeen == 100)
now = 200
memory:Observe(1,2,3)
assert(point.observations == 2 and point.serverVisits == 1 and point.lastSeen == 200)
assert(memory:Save() and not memory.dirty)
local sameServer = createMemory(http, store, 123, "server-a", clock)
sameServer:Observe(1,2,3)
assert(sameServer.records[1].serverVisits == 1, "re-execution is not a server visit")
local nextServer = createMemory(http, store, 123, "server-b", clock)
nextServer:Observe(1,2,3)
assert(nextServer.records[1].serverVisits == 2 and nextServer.records[1].observations == 3)
nextServer:Observe(10,20,30)
assert(#nextServer.records == 2)
assert(nextServer:Save() and files[path..".bak"], "backup written")
files[path] = "corrupt"
local recovered = createMemory(http, store, 123, "server-c", clock)
assert(recovered.status == "Backup recovered" and #recovered.records == 1)
assert(recovered:Save(), "recovered backup restores primary")
assert(createMemory(http, store, 456, "server-c", clock).records[1] == nil, "map isolation")
assert(not recovered:Observe(0/0,0,0) and not recovered:Observe(math.huge,0,0))
local session = createMemory(http, {}, 123, "a", clock)
session:Observe(1,1,1)
assert(not session:Save() and #session.records == 1, "session-only fallback")
local failing = createMemory(http, {write=function() error("disk full") end}, 123, "a", clock)
failing:Observe(1,1,1)
assert(not failing:Save() and failing.dirty, "failed save stays retryable")
local limited = createMemory(http, {}, 123, "a", clock)
limited.limit = 2
limited:Observe(1,1,1); limited:Observe(5,5,5)
assert(not limited:Observe(10,10,10) and #limited.records == 2, "bounded memory")
print("PASS: migration, nearby merge, timestamps, server visits, re-execution, backup recovery, map isolation, invalid coordinates, storage failure, capacity")
