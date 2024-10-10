if not isServer() then
    return
end

local PhunSpawn = PhunSpawn

local sphunsystem = nil

Events.LoadGridsquare.Add(function(square)

    if not sphunsystem then
        sphunsystem = SPhunSpawnSystem
    end
    sphunsystem.instance:verifyOnLoadSquare(square)

end)

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PhunSpawn.name and sphunsystem.instance.Commands[command] then
        sphunsystem.instance.Commands[command](player, args)
    end
end)
