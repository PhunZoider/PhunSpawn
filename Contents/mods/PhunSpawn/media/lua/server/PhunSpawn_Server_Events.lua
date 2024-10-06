if not isServer() then
    return
end

local PhunSpawn = PhunSpawn

Events.OnInitGlobalModData.Add(function()
    PhunSpawn:ini()
end)
