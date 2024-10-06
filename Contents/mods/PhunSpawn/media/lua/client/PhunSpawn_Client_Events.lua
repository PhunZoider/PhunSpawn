if not isClient() then
    return
end
local PhunSpawn = PhunSpawn

Events.OnInitGlobalModData.Add(function()
    PhunSpawn:ini()
end)

Events.OnReceiveGlobalModData.Add(function(key, data)
    if key == PhunSpawn.consts.spawnpoints then
        PhunSpawn.data.spawnPoints = data
        ModData.add(PhunSpawn.consts.spawnpoints, data)
    end

end)

local function contextMenu(playerIndex, context, worldObjects, test)

    local player = getSpecificPlayer(playerIndex)
    local md = player:getModData()
    local spawnerObj = nil

    for _, w in ipairs(worldObjects) do -- find object to interact with; code support for controllers
        local square = w:getSquare()
        if square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                local sprite = obj:getSprite():getName()
                if sprite == "phunspawn_01_1" or sprite == "phunspawn_01_0" then
                    spawnerObj = obj
                    break
                end
            end
        end
    end

    if spawnerObj then
        local data = PhunSpawn:getSpawnPoint(spawnerObj)
        if data then
            if data.key and data.discoverable ~= false then

                local option = context:addOptionOnTop(getText("IGUI_PhunSpawn_Activate"), worldObjects, function()
                    PhunSpawn:registerDiscovery(player, data.key)
                    getSoundManager():PlaySound("PhunSpawn_Activate", false, 0):setVolume(0.50);
                end, playerIndex)

                local isDiscoverd = PhunSpawn:isDiscovered(player, data.key) or data.autoDiscover == true

                local toolTip = ISToolTip:new();
                toolTip:setVisible(isDiscoverd);
                toolTip:setName(getText("IGUI_PhunSpawn_StrangeDevice"));
                if isDiscoverd then
                    toolTip.description = getText("IGUI_PhunSpawn_AlreadyActivated_Tooltip")
                else
                    toolTip.description = getText("IGUI_PhunSpawn_Activate_Tooltip")
                end
                option.notAvailable = isDiscoverd
                option.toolTip = toolTip;
            end
        end
    end

    if isAdmin() then

        context:addOption(getText("IGUI_PhunSpawn_Create_Spawner"), worldObjects, function()
            getCell():setDrag(PhunSpawnCursor:new("phunspawn_01_1", true, player), playerIndex)
        end, playerIndex)

        if spawnerObj then
            context:addOption(getText("IGUI_PhunSpawn_Edit_Spawner"), worldObjects, function()
                PhunSpawnPointSettingUI.OnOpenPanel(player, spawnerObj)
            end, playerIndex)
        end
    end

    if isAdmin() or (SandboxVars.PhunSpawn.RespawnHospitalRooms and md and md.RHR) then
        context:addOptionOnTop(getText("IGUI_PhunSpawn_Exit_Room"), player, function()
            PhunSpawnSelectorUI.OnOpenPanel(player)
        end)
    end
end

Events.OnFillWorldObjectContextMenu.Add(contextMenu)

local function OnPlayerInit(player)
    PhunSpawn:PlayerInit(player)
    Events.OnPlayerUpdate.Remove(OnPlayerInit)
end
Events.OnPlayerUpdate.Remove(OnPlayerInit)

if Events["OnHospitalRoomTeleport"] then
    Events.OnHospitalRoomTeleport.Add(function(player)
        player:setHaloNote("Your head feels fuzzy", 255, 255, 0, 300);
        player:setHaloNote("Where are you?", 255, 255, 0, 300);
        player:Say("Hello? Is anyone there?");
    end)
end
