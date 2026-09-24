-- Local, versioned observation history. No remote collection or uploads.
return function(http, storage, placeId, jobId, clock)
    local memory = {records = {}, dirty = false, status = "Session only", limit = 3000}
    local path = "timijshax-spawns-" .. tostring(placeId) .. ".json"
    local buckets, lastGood = {}, nil
    local function finite(n) return type(n) == "number" and n == n and math.abs(n) <= 1000000 end
    local function bucket(x, y, z) return string.format("%d:%d:%d", math.floor(x), math.floor(y), math.floor(z)) end
    local function index(record)
        local k = bucket(record.x, record.y, record.z)
        buckets[k] = buckets[k] or {}
        table.insert(buckets[k], record)
        table.insert(memory.records, record)
    end
    local function nearby(x, y, z)
        for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
            for _, record in ipairs(buckets[bucket(x+dx, y+dy, z+dz)] or {}) do
                if (record.x-x)^2 + (record.y-y)^2 + (record.z-z)^2 <= 0.25 then return record end
            end
        end end end
    end
    local function timestamp(value)
        return type(value) == "number" and value == value and value >= 0 and value < 1e12 and math.floor(value) or 0
    end
    if storage.read then
        for _, candidate in ipairs({path, path .. ".bak"}) do
            local ok, raw = pcall(storage.read, candidate)
            if ok then
                local decodedOK, data = pcall(function() return http:JSONDecode(raw) end)
                if decodedOK and type(data) == "table" and (data.version == nil or data.version == 2 and data.placeId == placeId) then
                    local points = data.version == 2 and data.records or data
                    if type(points) == "table" then
                        for _, point in ipairs(points) do
                            if #memory.records >= memory.limit then break end
                            if type(point) == "table" then
                                local x,y,z = point.x or point[1], point.y or point[2], point.z or point[3]
                                if finite(x) and finite(y) and finite(z) and not nearby(x,y,z) then
                                    index({x=x,y=y,z=z, observations=timestamp(point.observations),
                                        firstSeen=timestamp(point.firstSeen), lastSeen=timestamp(point.lastSeen),
                                        serverVisits=timestamp(point.serverVisits),
                                        lastServer=type(point.lastServer) == "string" and point.lastServer:sub(1,128) or ""})
                                end
                            end
                        end
                        lastGood = raw
                        memory.dirty = data.version ~= 2 or candidate ~= path
                        memory.status = candidate == path and "Memory loaded" or "Backup recovered"
                        break
                    end
                end
            end
        end
    end
    function memory:Observe(x,y,z)
        if not finite(x) or not finite(y) or not finite(z) then return nil end
        local record = nearby(x,y,z)
        if not record then
            if #self.records >= self.limit then self.status = "Memory full (3000 locations)"; return nil end
            record = {x=x,y=y,z=z,observations=0,firstSeen=0,lastSeen=0,serverVisits=0,lastServer=""}
            index(record)
        end
        local now = clock()
        if record.firstSeen == 0 then record.firstSeen = now end
        record.lastSeen = now
        record.observations = record.observations + 1
        if record.lastServer ~= jobId or record.serverVisits == 0 then
            record.serverVisits = record.serverVisits + 1
            record.lastServer = jobId
        end
        self.dirty = true
        self.status = "New observations — save pending"
        return record
    end
    function memory:Save()
        if not storage.write then self.status = "Session only: file access unavailable"; return false end
        if not self.dirty then return true end
        local ok = pcall(function()
            local raw = http:JSONEncode({version=2, placeId=placeId, records=self.records})
            if lastGood then storage.write(path .. ".bak", lastGood) end
            storage.write(path, raw)
            lastGood = raw
        end)
        self.status = ok and "Memory saved locally" or "Save failed: memory kept in session"
        if ok then self.dirty = false end
        return ok
    end
    return memory
end
