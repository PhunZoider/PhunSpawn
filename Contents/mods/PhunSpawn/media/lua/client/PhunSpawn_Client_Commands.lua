if not isClient() then
    return
end
local PS = PhunSpawn
local Commands = {}

Commands.allSpawnPoints = function(player)
    PS.data.allSpawnPoints = player
end

Commands[PS.commands.getMyDiscoveries] = function(player, data)
    PS.data.discoveries[player:getUsername()] = data
end

-- Events.OnServerCommand.Add(function(module, command, arguments)
--     if module == PS.name and Commands[command] then
--         Commands[command](arguments)
--     end
-- end)

return Commands
