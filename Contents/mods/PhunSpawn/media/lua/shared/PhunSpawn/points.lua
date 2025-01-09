local PS = PhunSpawn
local PZ = PhunZones
require "PhunSpawn/core"

local tableTools = require("PhunZones/table")
local fileTools = require("PhunZones/files")
local allLocations = require("PhunZones/data")

local getActivatedMods = getActivatedMods

local function getRow(modId, data, omitMods)

    -- first key is the modid separated by a pipe
    -- if omitMods is true, we don't want to include the modid in the key
    -- otherwise, we split the key to see if any of the mods are active
    local process = true

    if omitMods and (modId ~= "vanilla" and modId ~= "none") then
        process = false
        local mods = luautils.split(modId .. "|", "|")
        for _, m in ipairs(mods) do
            if m and getActivatedMods():contains(m) then
                process = true
                break
            end
        end
    end

    if process then
        local results = {}
        -- to preserve the original data, we copy the entry
        local copy = tableTools:shallowCopyTable(data)
        for k, v in pairs(copy) do
            if v.enabled ~= true then
                results[k] = {
                    key = k,
                    pools = v.pools,
                    discoverable = v.discoverable ~= false,
                    autoDiscovered = v.autoDiscovered == true,
                    owner = v.owner or nil
                }
            end
        end
        return results
    end
    return nil
end

function PS:getBasePools(omitMods)

    local results = {}

    for modId, areas in pairs(allLocations or {}) do
        local rows = getRow(modId, areas, omitMods)
        if rows then
            for k, v in pairs(rows) do
                results[k] = v
            end
        end

    end

    return results
end

function PS:getModifiedPools(omitMods)

    local data = fileTools:loadTable(self.const.modifiedLuaFile) or {}
    ModData.add(self.const.modifiedData, data)
    ModData.transmit()

    local results = {}

    for modId, areas in pairs(data) do

        local rows = getRow(modId, areas, omitMods)
        if rows then
            for k, v in pairs(rows) do
                results[k] = v
            end
        end

    end

    return results
end

function PS:getMergedPools(omitMods, modifiedDataSet)
    local core = self:getBasePoints(omitMods)
    local modified = modifiedDataSet or self:getModifiedPoints(omitMods)
    local results = tableTools:mergeTables(core or {}, modified or {})
    return results
end

function PS:getActivatedPoints(omitMods)

    -- each entry has a pool with one or more points in it
    -- when the system is spawning a new point, it will choose an entry from the pool
    -- once that is chosen, it is added to the crystalised list
    -- alternatively, if a user places a point, it is also added to the crystalised list

    -- all the activated points
    local activated = ModData.getOrCreate(self.const.activated)

    -- get a complete list of base + modified pools
    local mergedPool = self:getMergedPools(omitMods)

    -- create a hashmap of the validated pools
    local hashMap = {}
    for key, entry in pairs(mergedPool) do
        for aKey, aEntry in pairs(entry.pools) do
            hashMap[key .. "." .. aKey] = aEntry
        end
    end

    -- validate the activated list. eg if a mod is removed, we need to remove the points from the list
    -- crystalised is a hashmap of the key and pool index. eg { "key" = 1 }
    -- key is a composite of modid and areaKey
    for key, entry in pairs(activated) do
        if not mergedPool[key] then
            -- remove the entry
            activated[key] = nil
            print("Removed invalid entry from activated list: " .. key)
        elseif not mergedPool[key][activated[key]] then
            -- the index is invalid, remove the entry
            activated[key] = nil
            print("Removed invalid index from activated list: " .. key)
        end
    end

    return activated

end

function PS:addModifiedPoint(key, index)
    local data = fileTools:loadTable(self.const.modifiedLuaFile) or {}
    data[key] = data[key] or {}
    data[key][index] = data[key][index] or {}
    data[key][index].enabled = true
    fileTools:saveTable(self.const.modifiedLuaFile, data)
    ModData.add(self.const.modifiedData, data)
    ModData.transmit()
end

function PS:activatePointByKey(key)
    local activated = ModData.getOrCreate(self.const.activated)
    activated[key] = activated[key] or 1
    ModData.save(self.const.activated, activated)
    ModData.transmit()
end

function PS:convertOldPoints()
    local data = fileTools:loadTable("PhunSpawn_Modified.lua") or {}
    local pools = self:getMergedPools(false)
    local result = {}
    local fakeKeys = {}

    for _, v in ipairs(data) do
        local mod = nil
        if v.mod and v.mod ~= "" then
            mod = v.mod
        end
        local owner = nil
        if v.owner and v.owner ~= "" then
            owner = v.owner
        end

        if owner == nil or owner == "Ubur" then
            if not mod then
                mod = "none"
                if owner then
                    mod = "user"
                end
            end
            if not result[mod] then
                result[mod] = {}
            end
            local key = ((v.city or "") .. " : " .. (v.title or "")):gsub("[^%w]", "")
            local proceed = true
            if mod == "user" then
                key = (owner .. ":" .. (v.title or "")):gsub("[^%w]", "")
                if fakeKeys[key] then
                    key = key .. " " .. fakeKeys[key]
                    fakeKeys[key] = fakeKeys[key] + 1
                else
                    fakeKeys[key] = 1
                end
            elseif pools[mod] and pools[mod][key] then
                proceed = false
            end
            if proceed then
                result[mod][key] = {
                    pools = {{v.x, v.y, v.z}}, -- pool
                    discoverable = v.discoverable == true and nil, -- discoverable
                    autoDiscovered = v.autoDiscovered == true or nil -- autoDiscovered
                }
            end
        end
    end

    self:debug("Converted old points to new format", result)
end
