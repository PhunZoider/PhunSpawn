if isServer() then
    return
end

local PS = PhunSpawn
local ClientSystem = CPhunSpawnSystem
local Commands = {}

Commands[PS.commands.getAllSpawns] = function(player, data)

    local d = PS:getHardCodedPoints()
    for i = 1, #data do
        table.insert(d, data[i])
    end

    ClientSystem.instance.data.allSpawnPoints = data
end

Commands[PS.commands.getMyDiscoveries] = function(player, data)
    ClientSystem.instance.data.discovered[player:getUsername()] = data
    ClientSystem.instance.data.discoveries[player:getUsername()] = data
end

return Commands
