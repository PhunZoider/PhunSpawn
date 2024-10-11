local PS = PhunSpawn
require "PhunSpawn_Server_System"

local SPhunSpawnSystem = SPhunSpawnSystem
local Commands = {}

Commands[PS.commands.killZombie] = function(player, args)
    local id = args.id
    print("Killing zombie with id: " .. id)
    local zombies = player:getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if instanceof(zombie, "IsoZombie") and zombie:getOnlineID() == id then
            zombie:removeFromWorld()
            zombie:removeFromSquare()
            return
        end
    end
end

Commands[PS.commands.getAllSpawns] = function(player)
    local spawns = SPhunSpawnSystem.instance:getSpawnPoints(true)
    sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, spawns)
end

Commands[PS.commands.upsertSpawnPoint] = function(player, args)
    SPhunSpawnSystem.instance:upsertSpawnPoint(args)
    local allData = SPhunSpawnSystem.instance:getSpawnPoints(true)
    -- sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, allData)
    -- print("Senfing")
    -- PhunTools:printTable(allData[args.key])
    SPhunSpawnSystem.instance:sendCommand(PS.commands.upsertedSpawnPoint, {
        username = player:getUsername(),
        data = allData[args.key]
    })
end

Commands[PS.commands.deleteSpawnPoint] = function(player, args)
    SPhunSpawnSystem.instance:deleteSpawnPoint(args.key)
    -- local allData = SPhunSpawnSystem.instance:getSpawnPoints(true)
    -- sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, allData)
end

Commands[PS.commands.getMyDiscoveries] = function(player)
    local data = SPhunSpawnSystem.instance:getPlayerDiscoveries(player)
    SPhunSpawnSystem.instance:sendCommand(player, PS.name, PS.commands.getMyDiscoveries, data)
end

Commands[PS.commands.registerDiscovery] = function(player, args)
    local discovered = SPhunSpawnSystem.instance:registerDiscovery(args.playername, args.key)
    SPhunSpawnSystem.instance:sendCommand(player, PS.name, PS.commands.getMyDiscoveries, discovered)
end

return Commands
