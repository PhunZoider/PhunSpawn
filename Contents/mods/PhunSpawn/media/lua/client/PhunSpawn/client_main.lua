if isServer() then
    return
end
local PS = PhunSpawn
local ClientSystem = CPhunSpawnSystem
local cached = nil
local cachedAll = nil
local cachedChunked = nil

local function addToChunks(point)
    if cachedChunked == nil then
        cachedChunked = {}
    end
    local ckey = math.floor(point.x / 10) .. "_" .. math.floor(point.y / 10)
    if not cachedChunked[ckey] then
        cachedChunked[ckey] = {}
    end
    table.insert(cachedChunked[ckey], ckey)
end

function PS:getChunk(ckey)
    if cachedAll == nil then
        self:getAllSpawnPoints()
    end
    return cachedChunked[ckey]
end

function PS:getAllSpawnPoints(reload)

    if cachedAll ~= nil and not reload then
        return cachedAll
    end

    local points = {}

    -- add all the hard coded points
    local defaults = self:defaultPoints()
    for k, v in pairs(defaults) do
        v.default = true
        points[k] = v
    end

    local fromModData = ModData.get(self.consts.spawnpoints) or {}
    for k, v in pairs(fromModData) do
        points[k] = v
    end

    cachedAll = points
    return points

end

function PS:getSpawnPoints(reload)

    if cached ~= nil and not reload then
        return cached
    end

    return self:getAllSpawnPoints(reload)

end

function PS:getRandomPoint()

    local points = self:getSpawnPoints()
    local keys = {}
    for k, v in pairs(points) do
        table.insert(keys, k)
    end
    local key = keys[ZombRand(#keys) + 1]
    return points[key]

end

function PS:getRandomUndiscovered(fromX, fromY, closerThan)

    local PhunSpawnPoints = self:getSpawnPoints()
    local discovered = ClientSystem.instance:getPlayerDiscoveries(getPlayer())
    local closerThan = closerThan or 500

    local points = {}
    for k, v in pairs(PhunSpawnPoints) do
        local distance = IsoUtils.DistanceTo(fromX, fromY, v.x, v.y)
        if distance < closerThan then
            table.insert(points, v)
        end
        if #points > 10 then
            break
        end
    end

    if #points == 0 then
        return nil
    end
    return points[ZombRand(#points) + 1]

end

function PS:doRandomUndiscovered(player)

    local sq = player:getSquare()
    local discovered = ClientSystem.instance:getPlayerDiscoveries(player)
    local found = false
    local point = self:getRandomUndiscovered(sq:getX(), sq:getY())
    local unlearned = ModData.getOrCreate("PhunSpawn_Learned")
    if point then

        -- if discovered[point.key] then
        --     discovered[point.key] = nil
        -- end
        -- unlearned[point.key] = nil
        if not unlearned[point.key] and not discovered[point.key] then
            found = true
            local radius = 50
            -- Generate a random angle (in radians) between 0 and 2π
            local angle = ZombRand(math.pi * 2)

            -- Generate a random distance between 0 and the specified radius
            local distance = ZombRand(radius)

            -- Calculate the new point's x and y coordinates
            local newX = point.x + math.cos(angle) * distance
            local newY = point.y + math.sin(angle) * distance

            self:drawSymbol(newX, newY, "Circle", player:getPlayerNum())
            unlearned[point.key] = {
                x = newX,
                y = newY
            }

            local sound = "PhunSpawn_Huh_Male"
            if player:isFemale() then
                sound = "PhunSpawn_Huh_Female"
            end
            local rnd = ZombRand(2) + 1
            getSoundManager():PlaySound(sound .. rnd, false, 0):setVolume(0.90);
            player:setHaloNote(getText("IGUI_PhunSpawn_IHaveMarkedOnMap"))
        end

    end

    if not found then
        player:setHaloNote(getText("IGUI_PhunSpawn_NoDiscovery"))
    end
end

function PS:removeSymbol(x, y)
    local p = getPlayer() or getSpecificPlayer(0)
    if not p then
        return
    end
    if not ISWorldMap_instance then
        ISWorldMap.ShowWorldMap(p)
        ISWorldMap.HideWorldMap(p)
    end
    local index = ISWorldMap_instance.mapAPI:getSymbolsAPI():hitTest(x, y)
    if index > -1 then
        ISWorldMap_instance.mapAPI:getSymbolsAPI():removeSymbolByIndex(index)
    end

    local count = ISWorldMap_instance.mapAPI:getSymbolsAPI():getSymbolCount()

    for i = 1, count do
        local symbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():getSymbolByIndex(i)
        if symbol then
            local wx = math.floor(symbol:getWorldX())
            if wx == math.floor(x) then
                local wy = math.floor(symbol:getWorldY())
                if wy == math.floor(y) then
                    ISWorldMap_instance.mapAPI:getSymbolsAPI():removeSymbolByIndex(i)
                    break
                end
            end
        end
    end

end

function PS:drawSymbol(x, y, symbolName, playerNum, scale)
    if not ISWorldMap_instance then
        ISWorldMap.ShowWorldMap(playerNum)
        ISWorldMap.HideWorldMap(playerNum)
    end
    local newSymbol = {}
    newSymbol.symbol = symbolName
    newSymbol.r = 1 -- ISWorldMap_instance.symbolsUI.currentColor:getR()
    newSymbol.g = 0 -- ISWorldMap_instance.symbolsUI.currentColor:getG()
    newSymbol.b = 1 -- ISWorldMap_instance.symbolsUI.currentColor:getB()
    local textureSymbol = ISWorldMap_instance.mapAPI:getSymbolsAPI():addTexture(newSymbol.symbol, x, y)
    textureSymbol:setRGBA(newSymbol.r, newSymbol.g, newSymbol.b, 1.0)
    textureSymbol:setAnchor(0.5, 0.5)
    textureSymbol:setScale(ISMap.SCALE * (scale or 10))
end

-- ???
Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PS.name and command == "OnEat_VentClue" then
        PS:doRandomUndiscovered(getPlayer())
    end
end)
