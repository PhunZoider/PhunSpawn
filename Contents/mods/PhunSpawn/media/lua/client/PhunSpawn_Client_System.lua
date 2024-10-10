if not isClient() then
    return
end
local PS = PhunSpawn
local Commands = require "PhunSpawn_Client_Commands"
CPhunSpawnSystem = CGlobalObjectSystem:derive("CPhunSpawnSystem")
local spawnSystem = CPhunSpawnSystem

function spawnSystem:new()
    local o = CGlobalObjectSystem.new(self, "phunspawn")
    o.data = {
        spawnPoints = ModData.getOrCreate(PS.consts.spawnpoints),
        allSpawnPoints = nil,
        discovered = ModData.getOrCreate(PS.consts.discoveries)
    }
    ModData.request(PS.consts.spawnpoints)
    sendClientCommand(PS.name, PS.commands.getMyDiscoveries, {})
    return o
end

function spawnSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function spawnSystem:newLuaObject(globalObject)
    local o = CPhunSpawnObject:new(self, globalObject)
    return o
end

function spawnSystem:OnServerCommand(command, args)
    if Commands[command] then
        Commands[command](args)
    end
end

function spawnSystem:discoverSquare(square, player)
    local obj = self:getIsoObjectOnSquare(square)
    if obj then
        self:discoverObject(obj, player)
    end
    return obj
end

function spawnSystem:discoverObject(obj, player)
    if obj then
        local data = self:getSpawnPoint(obj)
        if data then
            if data.key and data.discoverable ~= false then
                if data.autoDiscovered ~= true and self:isDiscovered(player, data.key) then
                    player:Say(getText("IGUI_PhunSpawn_AlreadyActivated"))
                else
                    PS:registerDiscovery(player, data.key)
                    getSoundManager():PlaySound("PhunSpawn_Activate", false, 0):setVolume(0.50);
                    player:Say(getText("IGUI_PhunSpawn_Activating"))
                end
            end
        end
    end
end

function spawnSystem:registerDiscovery(player, key)
    local name = type(player) == "string" and player or player:getUsername()
    local discoveries = self:getPlayerDiscoveries(player)
    discoveries[key] = true
    -- tell server about this discovery
    sendServerCommand(PS.name, PS.commands.registerDiscovery, {
        playername = name,
        key = key
    })
    return discoveries
end

function spawnSystem:removeDiscovery(player, key)
    self:getPlayerDiscoveries(player)[key] = nil
end

function spawnSystem:isDiscovered(player, key)
    local discoveries = self:getPlayerDiscoveries(player)
    return discoveries[key] == true
end

function spawnSystem:getPlayerDiscoveries(player)
    local name = type(player) == "string" and player or player:getUsername()
    if not self.data.discovered then
        self.data.discovered = {}
    end
    if not self.data.discovered[name] then
        self.data.discovered[name] = {}
    end
    return self.data.discovered[name]
end

function spawnSystem:deleteObject(obj, player)

    local key = PS:getKey(obj)
    PS:removeDiscovery(player, key)
    self:sendCommand(player or getSpecificPlayer(0), PS.commands.deleteSpawnPoint, {
        key = key
    })
    sledgeDestroy(obj);

end

function spawnSystem:upsertObject(obj, data)

    obj:getModData().PhunSpawn = data
    self:sendCommand(getSpecificPlayer(0), PS.commands.upsertSpawnPoint, data)
end

function spawnSystem:createAtSquare(square, player, data)
    self:sendCommand(player, PS.commands.upsertSpawnPoint, data)
end

function spawnSystem:getSpawnPoint(keyOrObj)
    local key = PS:getKey(keyOrObj)
    return self.data.spawnPoints[key]
end

CGlobalObjectSystem.RegisterSystemClass(spawnSystem)

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

Events.DoSpecialTooltip.Add(DoSpecialTooltip)

local _lastHighlighted = nil

Events.OnObjectLeftMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and spawnSystem:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
        local hasModData = object:getModData()
    end
end)

Events.OnObjectRightMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and spawnSystem:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
    end
end)