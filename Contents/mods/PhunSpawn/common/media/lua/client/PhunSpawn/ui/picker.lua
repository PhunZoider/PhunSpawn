if isServer() then
    return
end
require "ISUI/ISCollapsableWindow"
require "PhunSpawn/client_main"
local Core = PhunSpawn
local Client = Core.client
local tools = require "PhunSpawn/ui/ui_utils"
local ListPanel = require "PhunSpawn/ui/list_panel"
local MapPanel = require "PhunSpawn/ui/map_panel"

-- ---------------------------------------------------------------------------
-- The spawn point picker: the places this character knows, by city, on the
-- left, and their own map on the right.
--
-- Clicking a city opens it to show its points and glides the map to fit
-- them. Clicking a point, in the list or on the map, selects it, and the
-- spawn button puts you there.
--
-- The list is the vendored list panel rather than a second kind of list,
-- used as an accordion: one city open at a time, its points as rows beneath
-- it. The columns are deliberately NOT sortable. A header click sorts every
-- row, and would scatter the points away from the city they sit under.
--
-- Everything drawn here comes out of Client.points, the payload, and never
-- out of the registry. The payload is what this character is allowed to know;
-- the registry on a client knows every point there is.
--
-- Whether the button does anything is the server's call (placement.lua).
-- Client.canSpawn only decides whether it is drawn enabled.
-- ---------------------------------------------------------------------------

local FONT_SCALE = tools.FONT_SCALE
local PAD = math.max(10, math.floor(10 * FONT_SCALE))

-- ---------------------------------------------------------------------------
-- The list
-- ---------------------------------------------------------------------------

local PointList = ListPanel:derive("PhunSpawnPointList")

local function regionLabel(name)
    if name == "" then
        return getText("IGUI_PhunSpawn_Elsewhere")
    end
    return name
end

function PointList:new(x, y, width, height, player, picker)
    local o = ListPanel.new(self, x, y, width, height, player)
    o.picker = picker
    -- The region whose points are showing, by name. "" is a real value, the
    -- unnamed region, so nothing open is nil and never "".
    o.expanded = nil
    return o
end

function PointList:createChildren()
    ListPanel.createChildren(self)
    self.list.doDrawItem = ListPanel.defaultDrawRow
    self.list:setOnMouseDownFunction(self, self.onRowClick)

    self:addListColumn(getText("IGUI_PhunSpawn_Col_Place"), 0, {
        text = function(d)
            if d.kind == "region" then
                return (d.name == self.expanded and "-  " or "+  ") .. d.label
            end
            return "      " .. d.label
        end,
        color = function(d)
            if d.kind == "point" and not d.point.known then
                return 0.45, 0.45, 0.45
            end
            if d.kind == "region" and d.group.known == 0 then
                return 0.55, 0.55, 0.55
            end
            return nil
        end
    })
    self:addListColumn(getText("IGUI_PhunSpawn_Col_Known"), 0.7, {
        text = function(d)
            if d.kind == "region" then
                if d.group.known < d.group.total then
                    return tostring(d.group.known) .. " / " .. tostring(d.group.total)
                end
                return tostring(d.group.known)
            end
            if not d.point.known then
                return getText("IGUI_PhunSpawn_Undiscovered")
            end
            return ""
        end,
        align = "right"
    })

    self.spawnButton = self:addBottomButton(getText("IGUI_PhunSpawn_Btn_Spawn"), self.onSpawnClick, false)
end

function PointList:getFilterText(d)
    if d.kind == "point" then
        return d.label .. " " .. regionLabel(d.region)
    end
    return d.label
end

--- Rebuild the rows from Client.points. Hooked to OnPointsReceived by the
--- vendored panel (UI.refresh), so a fresh payload redraws an open window.
function PointList:refreshList()
    self:clearList()
    self.groups = Core.groupByRegion(Client.points or {})
    self.groupsByName = {}
    for _, group in ipairs(self.groups) do
        self.groupsByName[group.name] = group
        self:addListItem(regionLabel(group.name), {
            kind = "region",
            key = "region:" .. group.name,
            name = group.name,
            label = regionLabel(group.name),
            group = group
        })
        if group.name == self.expanded then
            for _, point in ipairs(group.points) do
                self:addListItem(point.label, {
                    kind = "point",
                    key = point.id,
                    label = point.label,
                    region = group.name,
                    point = point
                })
            end
        end
    end
    -- Now rather than on the next prerender, so a selectKey straight after a
    -- refresh finds its row.
    self:applyFilter()

    if Client.points == nil then
        self.description = getText("IGUI_PhunSpawn_Desc_Loading")
    elseif #self.groups == 0 then
        self.description = getText("IGUI_PhunSpawn_Desc_Nothing")
    elseif Client.pending then
        self.description = getText("IGUI_PhunSpawn_Desc_Pending")
    else
        self.description = getText("IGUI_PhunSpawn_Desc_Known")
    end

    if self.picker then
        self.picker:onListRefreshed()
    end
end
PointList.refresh = PointList.refreshList

--- The point on the selected row, or nil when the row is a city.
function PointList:selectedPoint()
    local d = self:selectedRow()
    if d and d.kind == "point" then
        return d.point
    end
    return nil
end

function PointList:onRowClick(d)
    if not d then
        return
    end
    if d.kind == "region" then
        self:toggleRegion(d.name)
    else
        self.picker:onPointSelected(d.point, true)
    end
end

--- Open a city, or close it if it is the open one.
--
-- A city with exactly one known point selects it as it opens, because the
-- only thing left to do there is press the button.
function PointList:toggleRegion(name)
    if self.expanded == name then
        self.expanded = nil
        self:refreshList()
        self:selectKey("region:" .. name)
        self.picker:onPointSelected(nil, false)
        return
    end

    self.expanded = name
    self:refreshList()
    local group = self.groupsByName[name]
    local only
    if group and group.known == 1 then
        for _, point in ipairs(group.points) do
            if point.known then
                only = point
            end
        end
    end
    if only then
        self:selectKey(only.id)
    else
        self:selectKey("region:" .. name)
    end
    self.picker:onPointSelected(only, false)
    if group then
        self.picker.map:showBounds(group.bounds)
    end
end

--- Select a point by id, opening its city. Used by a click on a map pin and
--- by the window opening on the last choice.
function PointList:selectPointId(id)
    for _, point in ipairs(Client.points or {}) do
        if point.id == id then
            local name = point.region or ""
            if self.expanded ~= name then
                self.expanded = name
                self:refreshList()
            end
            self:selectKey(id)
            return point
        end
    end
    return nil
end

function PointList:prerender()
    ListPanel.prerender(self)
    -- After the base, which sets enable on buttons that require a selection;
    -- this one requires more than that and decides for itself.
    local point = self:selectedPoint()
    local enabled = point ~= nil and point.known and Client.canSpawn
    self.spawnButton:setEnable(enabled)
    if point and point.known and not Client.canSpawn then
        self.spawnButton.tooltip = getText("IGUI_PhunSpawn_Tip_AlreadyPlaced")
    else
        self.spawnButton.tooltip = nil
    end
end

function PointList:onSpawnClick()
    local point = self:selectedPoint()
    if not point or not point.known or not Client.canSpawn then
        return
    end
    -- A new character gets one choice, so it is confirmed. An admin porting
    -- about is told where, but it is the same dialog: a misclick on a map is
    -- a long walk back either way.
    local text
    if Client.pending then
        text = getText("IGUI_PhunSpawn_Confirm_Spawn", point.label)
    else
        text = getText("IGUI_PhunSpawn_Confirm_Port", point.label)
    end
    local picker = self.picker
    tools.confirm(text, function()
        Client.spawn(point.id)
        if picker then
            picker:close()
        end
    end, self)
end

-- ---------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------

local Picker = ISCollapsableWindow:derive("PhunSpawnPicker")
Core.ui.picker = Picker
-- One per split screen player, by player number.
Picker.instances = {}

function Picker.open(player)
    if not player then
        return nil
    end
    local index = player:getPlayerNum()
    local instance = Picker.instances[index]
    if not instance then
        local core = getCore()
        local w = math.min(core:getScreenWidth() - 40, math.floor(1000 * FONT_SCALE))
        local h = math.min(core:getScreenHeight() - 40, math.floor(640 * FONT_SCALE))
        instance = Picker:new((core:getScreenWidth() - w) / 2, (core:getScreenHeight() - h) / 2, w, h, player)
        instance:initialise()
        instance:addToUIManager()
        Picker.instances[index] = instance
    else
        instance:setVisible(true)
        instance:bringToTop()
    end
    instance.list:refreshList()
    -- Whatever was cached may be stale: the timed discovery sweep announces a
    -- find but does not resend the list. The answer lands in refreshList.
    Client.refreshPoints()
    return instance
end

function Picker:new(x, y, width, height, player)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.player = player
    o.playerIndex = player:getPlayerNum()
    o.resizable = false
    o.title = getText("IGUI_PhunSpawn_PickerTitle")
    -- The view is placed once, on the first payload that has anything in it,
    -- and after that belongs to the player.
    o.viewPlaced = false
    return o
end

function Picker:createChildren()
    ISCollapsableWindow.createChildren(self)
    local top = self:titleBarHeight()
    local bottom = self:resizeWidgetHeight()
    local listW = math.max(math.floor(280 * FONT_SCALE), math.floor(self.width * 0.32))
    local contentH = self.height - top - bottom

    self.map = MapPanel:new(listW, top + PAD, self.width - listW - PAD, contentH - PAD * 2, self.playerIndex)
    self:addChild(self.map)
    -- A new character has seen nothing, so their own map is black. They get
    -- the whole map to choose on, as vanilla's spawn select does, and
    -- everybody else gets the map they have actually walked.
    self.map:initMap(not Client.pending)
    self.map:setOnPick(self, self.onPinClicked)

    self.list = PointList:new(0, top, listW, contentH, self.player, self)
    self.list:initialise()
    self.list:setShell(self)
    self:addChild(self.list)
end

--- The list has new rows. Keep the map's pins and highlight in step, and
--- place the view the first time there is anything to place it on.
function Picker:onListRefreshed()
    if not self.map then
        return
    end
    self.map:setPoints(Client.points)
    local point = self.list:selectedPoint()
    self.map:setSelected(point and point.id or nil, self.list.expanded)
    self.title = getText(Client.pending and "IGUI_PhunSpawn_PickerTitle" or "IGUI_PhunSpawn_PickerTitleKnown")

    if not self.viewPlaced and Client.points and #Client.points > 0 then
        self.viewPlaced = true
        self:placeInitialView()
    end
end

--- Open on the last choice if it is still known, else fit everything known.
function Picker:placeInitialView()
    local last = Client.lastChoice
    if last then
        local point = self.list:selectPointId(last)
        if point and point.known then
            self:onPointSelected(point, true)
            return
        end
    end
    local all
    for _, group in ipairs(self.list.groups or {}) do
        local b = group.bounds
        if b then
            if not all then
                all = {
                    x1 = b.x1,
                    y1 = b.y1,
                    x2 = b.x2,
                    y2 = b.y2
                }
            else
                all.x1 = math.min(all.x1, b.x1)
                all.y1 = math.min(all.y1, b.y1)
                all.x2 = math.max(all.x2, b.x2)
                all.y2 = math.max(all.y2, b.y2)
            end
        end
    end
    self.map:showBounds(all)
end

--- A point was chosen, or the choice was cleared (nil).
-- @param move  glide the map to it. False when the click was on the map
--              itself, where the player is already looking at it.
function Picker:onPointSelected(point, move)
    self.map:setSelected(point and point.id or nil, self.list.expanded)
    if move and point and point.known then
        self.map:showPoint(point)
    end
end

function Picker:onPinClicked(pointId)
    local point = self.list:selectPointId(pointId)
    if point then
        self:onPointSelected(point, false)
    end
end

function Picker:close()
    self:setVisible(false)
    self:removeFromUIManager()
    Picker.instances[self.playerIndex] = nil
end

return Picker
