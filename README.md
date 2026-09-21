# PhunSpawn

Spawn points for Project Zomboid **B42**, in single player and multiplayer.

A character starts knowing the few places the save gives them and finds the
rest by walking the map. A new character wakes up in an off grid arrival room
rather than on a kerb, so the first thirty seconds are theirs.

Part of the Phun mod family. Requires PhunInteriors.

## Status

**Scaffolding.** The registry, the unlock bookkeeping and the dispatch layer
are written and covered by `Tests/run.sh`. Nothing has run in game. What is
deliberately not built yet is listed under "Not built" below, and each one is
marked `TODO` at the place it belongs.

## What it does

| | The usual approach | PhunSpawn |
|---|---|---|
| Spawn list | A fixed list everybody sees | Per character, and earned by going there |
| Where the list lives | A mod's own store | The character record, so it survives losing `global_mod_data.bin` |
| Waking up | On a kerb, in whatever is standing on it | In an off grid room, when PhunInteriors is installed |
| Adding points | Edit the mod | Register one from a vanilla hook |
| SP and MP | Two implementations that drift | One code path, dispatched through `Core.dispatch` |

## How a point is unlocked

Four ways, and the value is on the point:

- `start` is known from character creation. Granted on **read** rather than
  stamped once, so a point added to the start set in a later version reaches
  existing characters with no migration to write.
- `explore` is unlocked by getting within `DiscoveryRadius`. The sweep runs on
  `EveryOneMinute` and deliberately not on every movement update: a point is a
  place you walk to and stay near for a moment, not a tripwire you can sprint
  through.
- `built` is unlocked by putting the marker down.
- `granted` is unlocked by something else entirely: another mod, a quest, an
  admin.

`explore` is the **default**, because the safe default is the one that gives
nothing away. A point meant to be known has to say so.

## Where the truth lives

The unlock list is a table in the character's own modData. `IsoPlayer.save`
reaches `IsoMovingObject.save`, which writes the modData `KahluaTable` into the
character record, so an unlock survives a restart, a wipe of
`global_mod_data.bin`, and anything our own store could lose.

`Core.unlocked` is a server side **cache** of that, rebuilt on login, so a
lookup does not reach into the character record every time somebody moves. The
record is the truth and the cache is the copy; `Tests/run.sh` refuses a second
write site, because a copy maintained in two places is a copy that disagrees
with the truth, which reads as a player losing an unlock they can see they
have.

It is per **character** and deliberately so. Discovery is the mechanic, and an
account wide list would hand the second character a map that is already solved.

## The arrival room

PhunInteriors is a hard dependency. The arrival room is one of its off grid
rooms, the cell uses its tiles, and a player leaving the room for the point
they picked goes out through its exit (`PhunInteriors.sendTo`). So the room's
lease and "Step outside" are cleared properly, and zombies are pushed off the
landing square when you arrive.

The room is registered with **no binding**. A PhunInteriors binding says which
vehicles or objects may lease a room, and nothing leases this one: a spawn room
is entered by being a new character, which is a different question from the
entitlement machinery and must not be squeezed into it.

## Adding your own points

Hook a **vanilla** event, not one of ours, and register from inside it:

```lua
Events.OnInitGlobalModData.Add(function()
    if not PhunSpawn then return end          -- definitive by now
    PhunSpawn.registerPoint("theirmod.lighthouse", {
        label  = "Lighthouse",
        region = "Riverside",
        x = 6100, y = 5200, z = 0,
        discovery = "explore",
    })
end)
```

Every property falls out of that. `Events.OnInitGlobalModData` always exists,
so your position in the load order cannot break the `.Add`. By the time it
fires, all lua has loaded, so `PhunSpawn` either exists or genuinely is not
installed, and the nil check is decisive rather than a race.

**It must not be `OnGameStart`.** That is triggered only from
`zombie.gameStates.IngameState`, which a dedicated server does not have, so a
point registered there would exist on every client and on no server.

**And it must not be `if PhunSpawn then ... end` at file scope.** That works
standalone and fails silently when your file loads first. The nil check belongs
inside the deferred handler, not around it.

Registering after our own event has fired is fine. The reverse indexes rebuild
on the first read after any registration, so a point that turns up late is
indexed the moment it arrives. Our own `PhunSpawnOnRegisterPoints` event exists
and works, and is what a generated file reads best on, but the vanilla hook is
the one to use because it is the one nobody can get wrong.

## Layout

```
Contents/mods/PhunSpawn/common/
  mod.info                  id=phunspawn, versionMin=42.0.0, require=phuninteriors
  media/sandbox-options.txt
  media/lua/shared/PhunSpawn/    core, tools, points, interiors, defaults
  media/lua/server/PhunSpawn/    unlocks, placement, server_{commands,events}
  media/lua/client/PhunSpawn/    client_{main,commands,context,events}
  media/lua/client/PhunSpawn/ui/ picker, map_panel, list_panel, ui_utils
  media/lua/shared/Translate/EN/ ContextMenu.json, IG_UI.json, Sandbox.json

Tests/run.sh              syntax check, static checks and specs
Tests/lua/stubs.lua       PZ globals, faked just enough to load
Tests/lua/points_spec.lua the registry, the sort, discovery and the payload
Tests/root/PhunSpawn/     overlay carrying the test id, applied by deploy.cmd
```

## Verify before you claim anything works

```bash
bash Tests/run.sh
```

That parses every lua file with LuaJIT, runs four static checks and then the
specs. The static checks exist because each catches a bug class LuaJIT cannot
see:

- no function shadowing a field declared on the `PhunSpawn` table in
  `core.lua`, which silently replaces it at file load time,
- no writer of the unlock cache other than `unlocks.lua`,
- no local redeclared at the top level of one function (`Tests/shadow.pl`),
- no em dashes anywhere.

LuaJIT is the fastest way to catch a syntax error and it cannot catch API
misuse: PZ globals do not exist outside the game, and LuaJIT will happily
accept `next()` and `loadstring`, neither of which B42 exposes.

It is **not** a mock of the game. Anything needing an `IsoGridSquare` is tested
in game or not at all.

## Deployment

VS Code `emeraldwalk.runonsave` (see `.vscode/settings.json`) runs `deploy.cmd`
on every save. That builds four trees: the playable mod, the test id variant
`PhunSpawnTest` (the live mod overlaid with `Tests/root/PhunSpawn/`), and
Workshop upload staging for each. `xclude` is the xcopy exclude list.

## Not built

Marked `TODO` where each belongs:

- **The picker has never been opened in game.** It is written: cities on the
  left, which open to show their points and fit the map to them, and the
  player's own map on the right with a pin per known point. A new character
  gets the whole map, since theirs is still blank. The "Wake up here" button
  works **once**, for a new character, so it is a choice and not fast travel;
  after that the picker is a map. An admin on a server, or anyone in single
  player debug mode, can use it any time. It ignores a point's `room`, does
  not check that the spawn square is free, and has no joypad support.
- **Built points.** `Commands.buildPoint` is a stub. The design constraint is
  known: object modData does **not** survive a pickup reliably, and whether it
  does depends on which tile was clicked. So either the marker refuses to be
  picked up, or a built point must not depend on its modData surviving one.
- **The arrival room's `locations`.** The room registers with no stamps,
  because there is no map yet. A room with no stamps allocates nothing, which
  is the honest state of affairs.
- **The shipped points are placeholders.** Three vanilla coordinates that need
  checking against the map before they ship: a spawn point on a solid square
  drops a new character into geometry and nothing here can tell.
