if not isServer() then
    return
end
require "PhunSpawn_Server_System"
local Commands = require "PhunSpawn_Server_Commands"
local PhunSpawn = PhunSpawn

Events.LoadGridsquare.Add(function(square)
    SPhunSpawnSystem.instance:verifyOnLoadSquare(square)
end)

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PhunSpawn.name and Commands[command] then
        Commands[command](player, args)
    end
end)

-- Events.OnSeeNewRoom.Add(function(room)
--     print("OnSeeNewRoom ", room:getName())
-- end)
