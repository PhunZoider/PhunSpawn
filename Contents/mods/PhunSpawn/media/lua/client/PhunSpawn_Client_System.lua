if not isClient() then
    return
end
local PS = PhunSpawn
local Commands = require "PhunSpawn_Client_Commands"
CPhunSpawnSystem = CGlobalObjectSystem:derive("spawnSystem")
local spawnSystem = CPhunSpawnSystem

function spawnSystem:new()
    local o = CGlobalObjectSystem.new(self, "phunspawn")
    return o
end

function spawnSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoThumpable") and isoObject:getName() == "PhunSpawnPoint"
end

function spawnSystem:newLuaObject(globalObject)
    local o = CPhunSpawnObject:new(self, globalObject)
    return o
end

function spawnSystem:OnServerCommand(command, args)
    if Commands[command] then
        Commands[command](args)
    end
end

CGlobalObjectSystem.RegisterSystemClass(spawnSystem)

local function DoSpecialTooltip1(tooltip, square)

    local playerObj = getSpecificPlayer(0)
    local layout = tooltip:beginLayout()
    tooltip:DrawTextCentre(tooltip:getFont(), "Frank", tooltip:getWidth() / 2, 5, 1, 1, 1, 1)
    tooltip:adjustWidth(5, "Frank")
    local y = layout:render(5, 5 + getTextManager():getFontHeight(tooltip:getFont()), tooltip)
    tooltip:setHeight(y + 5)
    tooltip:endLayout(layout)
end

local function DoSpecialTooltip(tooltip, square)
    tooltip:setWidth(100)
    tooltip:setMeasureOnly(true)
    DoSpecialTooltip1(tooltip, square)
    tooltip:setMeasureOnly(false)
    DoSpecialTooltip1(tooltip, square)
end

Events.DoSpecialTooltip.Add(DoSpecialTooltip)

local _lastHighlighted = nil

Events.OnObjectLeftMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and spawnSystem:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
        local hasModData = object:getModData()
    end
end)

Events.OnObjectRightMouseButtonUp.Add(function(object, x, y)
    if _lastHighlighted then
        _lastHighlighted:setHighlighted(false, false);
    end
    if object and spawnSystem:isValidIsoObject(object) then
        object:setHighlighted(true, false);
        _lastHighlighted = object
    end
end)
