if not isClient() then
    return
end

local PS = PhunSpawn
local Commands = {}

Commands[PS.commands.getAllSpawns] = function(player, data)

    local d = PS:getHardCodedPoints()
    for i = 1, #data do
        table.insert(d, data[i])
    end

    CPhunSpawnSystem.instance.data.allSpawnPoints = data
end

Commands[PS.commands.getMyDiscoveries] = function(player, data)
    CPhunSpawnSystem.instance.data.discovered[player:getUsername()] = data
    CPhunSpawnSystem.instance.data.discoveries[player:getUsername()] = data
end

-- Commands[PS.commands.upsertedSpawnPoint] = function(args)
--     local data = args.data
--     local spawner = CPhunSpawnSystem.instance:getIsoObjectAt(data.x, data.y, data.z)
--     if spawner then
--         -- lol, wtf?
--         for i = 1, getOnlinePlayers():size() do
--             local p = getOnlinePlayers():get(i - 1)
--             if p:isLocalPlayer() and args.username == p:getUsername() then
--                 PhunSpawnPointSettingUI.OnOpenPanel(p, spawner)
--                 break
--             end
--         end
--     end

-- end

return Commands
