if isServer() then
    return false
end
local PS = PhunSpawn
local Commands = require "PhunSpawn/client_commands"
local objectName = "CPhunSpawnSystem"
local CPhunSpawnSystem = CGlobalObjectSystem:derive(objectName)
local System = CPhunSpawnSystem

function System:new()
    local o = CGlobalObjectSystem.new(System, "phunspawn")
    o.data = {
        spawnPoints = ModData.getOrCreate(PS.consts.spawnpoints),
        allSpawnPoints = nil,
        discovered = ModData.getOrCreate(PS.consts.discoveries),
        learned = ModData.getOrCreate("PhunSpawn_Learned")
    }
    ModData.request(PS.consts.spawnpoints)
    sendClientCommand(PS.name, PS.commands.getMyDiscoveries, {})
    return o
end

function System:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function System:newLuaObject(globalObject)
    local o = CPhunSpawnObject:new(System, globalObject)
    return o
end

function System:OnServerCommand(command, args)
    if Commands[command] then
        Commands[command](args)
    end
end

function System:discoverSquare(square, player)
    local obj = System:getIsoObjectOnSquare(square)
    if obj then
        System:discoverObject(obj, player)
    end
    return obj
end

function System:discoverObject(obj, player)
    if obj then
        local data = System:getSpawnPoint(obj)
        if data then
            if data.key and data.discoverable ~= false then
                if data.autoDiscovered ~= true and System:isDiscovered(player, data.key) then
                    player:Say(getText("IGUI_PhunSpawn_AlreadyActivated"))
                else
                    System:registerDiscovery(player, data.key)
                    getSoundManager():PlaySound("PhunSpawn_Activate", false, 0):setVolume(0.50);
                    player:Say(getText("IGUI_PhunSpawn_Activating"))
                end
            end
        end
    end
end

function System:registerDiscovery(player, key)
    local name = type(player) == "string" and player or player:getUsername()
    local discoveries = System:getPlayerDiscoveries(player)
    discoveries[key] = true
    -- tell server about this discovery
    sendServerCommand(PS.name, PS.commands.registerDiscovery, {
        playername = name,
        key = key
    })

    -- remove related symbol on map if its still about
    local unlearned = ModData.getOrCreate("PhunSpawn_Learned")
    if unlearned[key] then
        PS:removeSymbol(unlearned[key].x, unlearned[key].y)
        unlearned[key] = nil
    end

    return discoveries
end

function System:removeDiscovery(player, key)
    System:getPlayerDiscoveries(player)[key] = nil
end

function System:isDiscovered(player, key)
    local discoveries = System:getPlayerDiscoveries(player)
    return discoveries[key] == true
end

function System:getPlayerDiscoveries(player)
    local name = type(player) == "string" and player or player:getUsername()
    if not System.data.discovered then
        System.data.discovered = {}
    end
    if not System.data.discovered[name] then
        System.data.discovered[name] = {}
    end
    return System.data.discovered[name]
end

function System:deleteObject(obj, player)

    local key = PS:getKey(obj)
    System:removeDiscovery(player, key)
    System:sendCommand(player or getSpecificPlayer(0), PS.commands.deleteSpawnPoint, {
        key = key
    })
    sledgeDestroy(obj);

end

function System:createFromData(player, data)
    local sq = getSquare(data.x, data.y, data.z)
    if sq then
        System:createAtSquare(sq, player, data)
        System:registerDiscovery(player, data.key)
        local item = player:getInventory():getFirstTypeRecurse("Escape Vent")
        if item then
            player:getInventory():DoRemoveItem(item)
        end
    end
end

function System:upsertObject(obj, data)

    obj:getModData().PhunSpawn = data
    System:sendCommand(getSpecificPlayer(0), PS.commands.upsertSpawnPoint, data)
end

function System:createAtSquare(square, player, data)
    System:sendCommand(player, PS.commands.upsertSpawnPoint, data)
end

function System:getSpawnPoint(keyOrObj)
    local key = PS:getKey(keyOrObj)
    return PS:getSpawnPoints()[key] or nil
end

function System:getDefaultCityName(x, y)
    if PhunZones and PhunZones.getLocation then
        local zone = PhunZones:getLocation(x, y)
        if zone and zone.title then
            return zone.title
        else
            return "Kentucky"
        end
    end

    local points = PS:getSpawnPoints()
    local distance = 100
    local cellX, cellY = math.floor(x / 300), math.floor(y / 300)
    local city = cellX .. ", " .. cellY
    for k, v in pairs(points) do
        local dist = IsoUtils.DistanceTo(v.x, v.y, x, y)
        if dist < distance then
            distance = dist
            city = v.city
        end
    end
    return city or (cellX .. ", " .. cellY)

end

CGlobalObjectSystem.RegisterSystemClass(System)

local function DoSpecialTooltip1(tooltip, square)

    local playerObj = getSpecificPlayer(0)
    local layout = tooltip:beginLayout()
    tooltip:DrawTextCentre(tooltip:getFont(), "Frank", tooltip:getWidth() / 2, 5, 1, 1, 1, 1)
    tooltip:adjustWidth(5, "Frank")
    local y = layout:render(5, 5 + getTextManager():getFontHeight(tooltip:getFont()), tooltip)
    tooltip:setHeight(y + 5)
    tooltip:endLayout(layout)
end

local function DoSpecialTooltip(tooltip, square)
    tooltip:setWidth(100)
    tooltip:setMeasureOnly(true)
    DoSpecialTooltip1(tooltip, square)
    tooltip:setMeasureOnly(false)
    DoSpecialTooltip1(tooltip, square)
end

-- Events.DoSpecialTooltip.Add(DoSpecialTooltip)

local _lastHighlighted = nil

Events.OnObjectLeftMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and System:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
        local hasModData = object:getModData()
    end
end)

Events.OnObjectRightMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and System:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
    end
end)
