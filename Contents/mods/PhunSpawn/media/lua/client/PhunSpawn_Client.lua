if not isClient() then
    return
end
local PhunSpawn = PhunSpawn

function PhunSpawn:PlayerInit(player)

    if SandboxVars.PhunSpawn.RespawnHospitalRooms then
        local md = player:getModData()
        if md.RHR then
            -- player is joining in a hospital room
        end
    end
end
