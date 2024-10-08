local PS = PhunSpawn

local Commands = {}
Commands.killZombie = function(_, args)
    local id = args.id
    local zombies = getCell():getZombieList()
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
    local spawns = PS:getSpawnPoints(true)
    sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, spawns)
end

Commands[PS.commands.upsertSpawnPoint] = function(player, args)
    PS:upsertSpawnPoint(args)
    local allData = PS:getSpawnPoints(true)
    sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, allData)
end

Commands[PS.commands.deleteSpawnPoint] = function(player, args)
    PS:deleteSpawnPoint(args.key)
    local allData = PS:getSpawnPoints(true)
    sendServerCommand(player, PS.name, PS.commands.allSpawnPoints, allData)
end

Commands[PS.commands.getMyDiscoveries] = function(player)
    local data = PS:getDiscoveries(player)
    sendServerCommand(player, PS.name, PS.commands.getMyDiscoveries, data)
end

Commands[PS.commands.registerDiscovery] = function(player, args)
    local discovered = PS:registerDiscovery(args.playername, args.key)
    sendServerCommand(player, PS.name, PS.commands.getMyDiscoveries, discovered)
end

return Commands
