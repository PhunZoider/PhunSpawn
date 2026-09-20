if isClient() then
    return
end
require "PhunSpawn/points"
require "PhunSpawn/tools"
require "PhunSpawn/interiors"
require "PhunSpawn/defaults"
local Core = PhunSpawn
local Commands = require "PhunSpawn/server_commands"
local Unlocks = require "PhunSpawn/unlocks"

local started = false

local function start()
    if started then
        return
    end
    started = true

    Core.data = ModData.getOrCreate(Core.consts.modDataKey)
    Core.refreshSettings()

    -- Points first, then anything that reads them.
    --
    -- This runs on OnInitGlobalModData, which is long after every mod's lua
    -- has loaded, so by the time it fires every listener that is ever going
    -- to be attached already is.
    Core.openRegistration()

    triggerEvent(Core.events.OnReady, Core)

    -- Counts only. What is MISSING is deliberately not reported here: a mod
    -- is free to register from any vanilla hook, which can land after this
    -- line, and a boot time warning about a set that turns up a moment later
    -- is worse than no warning at all.
    Core.logLn("ready. " .. Core.describeRegistry())
end

Events.OnInitGlobalModData.Add(start)
Events.OnServerStarted.Add(start)

Events.OnClientCommand.Add(function(module, command, player, arguments)
    if module == Core.name and Commands[command] then
        Commands[command](player, arguments or {})
    end
end)

-- Discovery is checked on a timer rather than on every movement update.
--
-- EveryOneMinute is coarse on purpose. A point is a place you walk to and
-- stay near for a moment, not a tripwire you can sprint through, and running
-- a sweep over every online player at 60Hz to notice something that changes
-- once a session is how a mod becomes the reason a server is slow.
--
-- Note tools.onlinePlayers returns everyone on a server and only the local
-- players on a client, which is exactly right here: this file never loads on
-- a client.
Events.EveryOneMinute.Add(function()
    local players = Core.tools.onlinePlayers()
    if not players then
        return
    end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local point = Unlocks.checkDiscovery(player)
            if point then
                Core.respond(player, Core.commands.unlocked, {
                    id = point.id,
                    label = point.label
                })
            end
        end
    end
end)

-- There is deliberately no disconnect handler. B42 has no server side "a
-- player left" event at all: OnDisconnect is a CLIENT event meaning "you were
-- disconnected", it takes no player argument, and LuaEventManager declares no
-- equivalent. Nothing is lost by that here, because the unlock list lives in
-- the character record rather than in memory; Core.unlocked is only a cache
-- and a stale entry for somebody absent costs nothing.
