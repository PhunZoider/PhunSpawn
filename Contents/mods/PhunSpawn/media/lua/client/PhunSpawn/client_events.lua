if isServer() then
    return
end
local PS = PhunSpawn
local ClientSystem = CPhunSpawnSystem
local Cursor = PhunSpawnCursor

Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)

    local item = nil
    local playerObj = getSpecificPlayer(playerNum)
    for i = 1, #items do
        if not instanceof(items[i], "InventoryItem") then
            item = items[i].items[1]
        else
            item = items[i]
        end

        if item then
            local itemType = item:getType()
            if itemType == "Escape Vent" then
                local itemContainer = item:getContainer()
                local t = itemContainer and itemContainer:getType() or nil

                local toolTip = ISToolTip:new();
                toolTip:setVisible(false);
                toolTip:setName("Vent");
                toolTip.description = "Unpack and place to create new spawn point";

                local option = context:addOptionOnTop("Place Vent", playerObj, function()
                    getCell():setDrag(Cursor:new("phunspawn_01_4", true, playerObj), playerNum)
                end)
                if t == "none" then
                    option.notAvailable = false
                else
                    toolTip.description = "You need to unpack before you can place";
                    option.notAvailable = true
                end
                option.toolTip = toolTip;
            end
        end
    end
end)

local originalCanBeSafehouseFuntion = nil
Events.OnReceiveGlobalModData.Add(function(key, data)

    if key == PS.consts.spawnpoints then
        ModData.add(PS.consts.spawnpoints, data)
        PS:getSpawnPoints(true)

    elseif key == PS.consts.discoveries then
        ModData.add(PS.consts.discoveries, data)
        ClientSystem.instance.data.discovered = ModData.getOrCreate(PS.consts.discoveries)

    end

    if originalCanBeSafehouseFuntion == nil then
        originalCanBeSafehouseFuntion = SafeHouse.canBeSafehouse
        SafeHouse.canBeSafehouse = function(square, player)
            if PS.settings.AllowSafehouseCreationIfVentExsts then
                local md = player:getModData()
                if SandboxVars.PhunSpawn.RespawnHospitalRooms and md and md.RHR then
                    return getText("IGUI_PhunSpawn_NoSafehouseHere")
                end

                -- is this square in a building with an autoDiscover spawn point?
                local building = square:getBuilding()
                if building then
                    local def = building:getDef()
                    local points = PS:getSpawnPoints()
                    for k, point in pairs(points) do
                        if point.autoDiscovered then
                            if point.x >= def:getX() and point.x <= def:getX2() then
                                if point.y >= def:getY() and point.y <= def:getY2() then
                                    return getText("IGUI_PhunSpawn_NoSafehouseHere")
                                end
                            end
                        end
                    end
                end

                -- are we outside of map bounds?
                if square:getX() > 19800 and square:getY() > 12000 then
                    return getText("IGUI_PhunSpawn_NoSafehouseHere")
                end
            end
            return originalCanBeSafehouseFuntion(square, player)
        end
    end

end)

local function contextMenu(playerIndex, context, worldObjects, test)
    PS:showContext(playerIndex, context, worldObjects)
    -- local player = getSpecificPlayer(playerIndex)
    -- local md = player:getModData()
    -- local spawnerObj = nil

    -- for _, w in ipairs(worldObjects) do -- find object to interact with; code support for controllers
    --     local square = w:getSquare()
    --     if square then
    --         spawnerObj = ClientSystem.instance:getIsoObjectOnSquare(square)
    --     end
    -- end

    -- if spawnerObj then
    --     local data = ClientSystem.instance:getSpawnPoint(spawnerObj)
    --     if data and data.key then
    --         if data.discoverable ~= false then

    --             local option = context:addOptionOnTop(getText("IGUI_PhunSpawn_Activate"), worldObjects, function()
    --                 ClientSystem.instance:registerDiscovery(player, data.key)
    --                 getSoundManager():PlaySound("PhunSpawn_Activate", false, 0):setVolume(0.50);
    --             end, playerIndex)

    --             local isDiscoverd = ClientSystem.instance:isDiscovered(player, data.key) or data.autoDiscovered == true

    --             local toolTip = ISToolTip:new();
    --             toolTip:setVisible(isDiscoverd);
    --             toolTip:setName(getText("IGUI_PhunSpawn_StrangeVent"));
    --             if isDiscoverd then
    --                 toolTip.description = getText("IGUI_PhunSpawn_AlreadyActivated_Tooltip")
    --             else
    --                 toolTip.description = getText("IGUI_PhunSpawn_Activate_Tooltip")
    --             end
    --             option.notAvailable = isDiscoverd
    --             option.toolTip = toolTip;
    --         end
    --     end
    -- end

    -- if isAdmin() then

    --     context:addOption(getText("IGUI_PhunSpawn_Create_Spawner"), worldObjects, function()
    --         getCell():setDrag(Cursor:new("phunspawn_01_4", true, player), playerIndex)
    --     end, playerIndex)

    --     if spawnerObj then
    --         context:addOption(getText("IGUI_PhunSpawn_Edit_Spawner"), worldObjects, function()
    --             PS.ui.main.OnOpenPanel(player, spawnerObj)
    --         end, playerIndex)
    --     end
    -- end

    -- if isAdmin() or (SandboxVars.PhunSpawn.RespawnHospitalRooms and md and md.RHR) then
    --     context:addOptionOnTop(getText("IGUI_PhunSpawn_Exit_Room"), player, function()
    --         PS.ui.main.OnOpenPanel.OnOpenPanel(player)
    --     end)
    -- end

end

Events.OnFillWorldObjectContextMenu.Add(contextMenu)

local function OnKeyPressed(key)
    if key == getCore():getKey("Interact") then
        local player = getPlayer()
        if not player or player:isDead() then
            return
        end
        if MainScreen.instance:isVisible() then
            return
        end
        local sq = player:getSquare()
        if sq then
            local obj = ClientSystem.instance:getIsoObjectOnSquare(sq)
            if obj then
                ClientSystem.instance:discoverObject(obj, player)
                local md = obj:getModData().PhunSpawn
                local pd = player:getModData()
                if md and md.canEnter then
                    PhunSpawnSelectorUI.OnOpenPanel(player)
                end
            else
                ClientSystem.instance:discoverSquare(sq, player)
            end

        end
    end
end

Events.OnKeyPressed.Add(OnKeyPressed)

local function OnPlayerInit(player)
    PS:PlayerInit(player)
    Events.OnPlayerUpdate.Remove(OnPlayerInit)
end
Events.OnPlayerUpdate.Remove(OnPlayerInit)

if Events["OnHospitalRoomTeleport"] then

    Events.OnHospitalRoomTeleport.Add(function(player)
        if PS.settings.RespawnHospitalRooms == true then
            local maxHalo1 = 12 -- 1-6
            local maxSay = 3 -- 1

            local halo1 = ZombRand(maxHalo1) + 1
            local halo2
            repeat
                halo2 = ZombRand(maxHalo1) + 1
            until halo2 ~= halo1

            local say = ZombRand(maxSay) + 1

            player:setHaloNote(getText("IGUI_PhunSpawn_NewSpawnHalo" .. halo1), 255, 255, 0, 300);
            player:setHaloNote(getText("IGUI_PhunSpawn_NewSpawnHalo" .. halo2), 255, 255, 0, 300);
            player:setHaloNote(getText("IGUI_PhunSpawn_NewSpawnWhereAmI"), 255, 255, 0, 300);
            player:Say(getText("IGUI_PhunSpawn_NewSpawnSay" .. say));

            if PhunStuffUIWelcome then
                PhunStuffUIWelcome.OnOpenPanel(player:getPlayerNum(), player)
            end
        end
    end)

end

Events.OnInitGlobalModData.Add(function()

    local canCraft = PS.settings.AllowCraftingVents == true
    local manager = getScriptManager()
    local recipe = manager:getRecipe("PhunSpawn.Escape Vent")
    if recipe then
        recipe:setIsHidden(not canCraft)
    end

end)
