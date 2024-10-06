if not isClient() then
    return
end
local PhunSpawn = PhunSpawn
local Commands = {}

Commands.allSpawnPoints = function(player)
    PhunSpawn.data.allSpawnPoints = player
end

Commands[PhunSpawn.commands.getMyDiscoveries] = function(player, data)
    PhunSpawn.data.discoveries[player:getUsername()] = data
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunSpawn.name and Commands[command] then
        Commands[command](arguments)
    end
end)
