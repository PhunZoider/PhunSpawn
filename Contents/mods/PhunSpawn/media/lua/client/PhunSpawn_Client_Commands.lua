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

Commands[PS.commands.upsertedSpawnPoint] = function(player, data)
    local spawner = CPhunSpawnSystem.instance:getIsoObjectAt(data.x, data.y, data.z)
    PhunSpawnPointSettingUI.OnOpenPanel(self.character, spawner)
end

return Commands
