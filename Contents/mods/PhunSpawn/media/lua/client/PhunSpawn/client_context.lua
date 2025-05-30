if isServer() then
    return
end
local PS = PhunSpawn
local mainName = "PhunSpawn"
local clientSystem = nil
function PS:showContext(playerIndex, context, worldobjects)

    local player = getSpecificPlayer(playerIndex) or getPlayer()
    local md = player:getModData()
    local spawnerObj = nil
    if not clientSystem then
        local c = CPhunSpawnSystem
        -- clientSystem = c.instance
    end

    for _, w in ipairs(worldobjects) do -- find object to interact with; code support for controllers
        local square = w:getSquare()
        if square then
            spawnerObj = clientSystem:getIsoObjectOnSquare(square)
        end
    end

    if spawnerObj then
        local data = clientSystem:getSpawnPoint(spawnerObj)
        if data and data.key then
            if data.discoverable ~= false then
                local option = context:addOptionOnTop(getText("IGUI_PhunSpawn_Activate"), context, function()
                    clientSystem:registerDiscovery(player, data.key)
                    getSoundManager():PlaySound("PhunSpawn_Activate", false, 0):setVolume(0.50);
                end, playerIndex)

                local isDiscoverd = clientSystem:isDiscovered(player, data.key) or data.autoDiscovered == true

                local toolTip = ISToolTip:new();
                toolTip:setVisible(isDiscoverd);
                toolTip:setName(getText("IGUI_PhunSpawn_StrangeVent"));
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

    if isAdmin() or isDebugEnabled() then

        local mainMenu = nil
        local contextoptions = context:getMenuOptionNames()
        local mainMenu = contextoptions[mainName]

        if not mainMenu then
            -- there isn't one so create it
            mainMenu = context:addOption(mainName)
        end

        local sub = context:getNew(context)
        context:addSubMenu(mainMenu, sub)

        sub:addOption(getText("IGUI_PhunSpawn_Exit_Room"), worldobjects, function()
            PS.ui.main.OnOpenPanel.OnOpenPanel(player)
        end)

        sub:addOption(getText("IGUI_PhunSpawn_Create_Spawner"), worldobjects, function()
            getCell():setDrag(PhunSpawnCursor:new("phunspawn_01_4", true, player), playerIndex)
        end, playerIndex)

        if spawnerObj then
            sub:addOption(getText("IGUI_PhunSpawn_Edit_Spawner"), worldobjects, function()
                PS.ui.main.OnOpenPanel(player, spawnerObj)
            end, playerIndex)
        end

    end

    if PS.settings.RespawnHospitalRooms and md.RHR then
        context:addOptionOnTop(getText("IGUI_PhunSpawn_Exit_Room"), player, function()
            PS.ui.main.OnOpenPanel.OnOpenPanel(player)
        end)
    end

end
