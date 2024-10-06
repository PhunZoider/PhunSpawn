if not isServer() then
    return
end

local PhunSpawn = PhunSpawn

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

Commands[PhunSpawn.commands.getAllSpawns] = function(player)
    local spawns = PhunSpawn:getSpawnPoints(true)
    sendServerCommand(player, PhunSpawn.name, PhunSpawn.commands.allSpawnPoints, spawns)
end

Commands[PhunSpawn.commands.upsertSpawnPoint] = function(player, args)
    PhunSpawn:upsertSpawnPoint(args)
    local allData = PhunSpawn:getSpawnPoints(true)
    sendServerCommand(player, PhunSpawn.name, PhunSpawn.commands.allSpawnPoints, allData)
end

Commands[PhunSpawn.commands.deleteSpawnPoint] = function(player, args)
    PhunSpawn:deleteSpawnPoint(args.key)
    local allData = PhunSpawn:getSpawnPoints(true)
    sendServerCommand(player, PhunSpawn.name, PhunSpawn.commands.allSpawnPoints, allData)
end

Commands[PhunSpawn.commands.getMyDiscoveries] = function(player)
    local data = PhunSpawn:getDiscoveries(player)
    sendServerCommand(player, PhunSpawn.name, PhunSpawn.commands.getMyDiscoveries, data)
end

Commands[PhunSpawn.commands.registerDiscovery] = function(player, args)
    local discovered = PhunSpawn:registerDiscovery(args.playername, args.key)
    sendServerCommand(player, PhunSpawn.name, PhunSpawn.commands.getMyDiscoveries, discovered)
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunSpawn.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
