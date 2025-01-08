local PS = PhunSpawn
require "PhunSpawn/server_system"

local ServerSystem = SPhunSpawnSystem
local Commands = {}

Commands[PS.commands.killZombie] = function(player, args)
    local id = args.id
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
    local spawns = PS:getAllSpawnPoints()
    sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, spawns)
end

Commands[PS.commands.upsertSpawnPoint] = function(player, args)
    ServerSystem.instance:upsertSpawnPoint(args)
    local allData = PS:getAllSpawnPoints(true)
    ServerSystem.instance:sendCommand(PS.commands.upsertedSpawnPoint, {
        username = player:getUsername(),
        data = allData[args.key]
    })
end

Commands[PS.commands.deleteSpawnPoint] = function(player, args)
    ServerSystem.instance:deleteSpawnPoint(args.key)
    PS:getAllSpawnPoints(true)
end

Commands[PS.commands.getMyDiscoveries] = function(player)
    local data = ServerSystem.instance:getPlayerDiscoveries(player)
    print("getMyDiscoveries", tostring(player) .. " " .. player and player.getUserName and player:getUsername() or "?")
    PhuNTools:printTable(data)
    ServerSystem.instance:sendCommand(player, PS.name, PS.commands.getMyDiscoveries, data)
end

Commands[PS.commands.registerDiscovery] = function(player, args)
    local discovered = ServerSystem.instance:registerDiscovery(args.playername, args.key)
    ServerSystem.instance:sendCommand(player, PS.name, PS.commands.getMyDiscoveries, discovered)
end

return Commands
