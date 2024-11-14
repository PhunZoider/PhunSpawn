if not isClient() then
    return
end
local PS = PhunSpawn
require "TimedActions/ISInventoryTransferAction"

-- Hook the original New Inventory Transfer Method
local originalNewInventoryTransaferAction = ISInventoryTransferAction.new
function ISInventoryTransferAction:new(player, item, srcContainer, destContainer, time)

    local itemType = item:getFullType()
    local destType = destContainer:getType()
    local action = originalNewInventoryTransaferAction(self, player, item, srcContainer, destContainer, time)
    if itemType == "PhunSpawn.Vent Clue" and destType ~= "floor" then
        action:setOnComplete(function()
            local invItem = player:getInventory():getItemFromTypeRecurse("PhunSpawn.Vent Clue")
            if invItem then
                invItem:getContainer():DoRemoveItem(invItem)
                PS:doRandomUndiscovered(player)
            end
        end)
    end
    return action

end
