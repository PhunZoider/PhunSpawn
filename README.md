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
| Spawn list | A fixed list everybody sees | Per player, earned by going there, and kept across deaths |
| Where the list lives | Lost with the character | The player's account record, so the next character can wake up there |
| Waking up | On a kerb, in whatever is standing on it | In an off grid room, when PhunInteriors is installed |
| Adding points | Edit the mod | Register one from a vanilla hook |
| SP and MP | Two implementations that drift | One code path, dispatched through `Core.dispatch` |

## How a point is unlocked

Five ways, and the value is on the point:

- `start` is known from character creation. Granted on **read** rather than
  stamped once, so a point added to the start set in a later version reaches
  existing characters with no migration to write.
- `explore` is unlocked by getting within `DiscoveryRadius`. The sweep runs on
  `EveryOneMinute` and deliberately not on every movement update: a point is a
  place you walk to and stay near for a moment, not a tripwire you can sprint
  through.
- `built` is reserved and unused: a phone a player builds is a `used` point
  like any other (see Player pay phones).
- `granted` is unlocked by something else entirely: another mod, a quest, an
  admin.
- `used` is unlocked by using the thing that marks it: a pay phone. Vanilla
  phones are swapped for ours at `PhoneChance` percent, no nearer than
  `PhoneDistance` to another, and each swapped phone is a point. Never listed
  while unused. By default never found by walking past either:
  `PhoneDiscoverRadius` is 0, so the phone has to be picked up. Set above 0,
  getting that close counts, and the phone rings once so the player knows
  it did. `DiscoveryRadius` is the same idea for places, which have nothing to
  pick up and so cannot be 0.

`explore` is the **default**, because the safe default is the one that gives
nothing away. A point meant to be known has to say so.

## The idea: a taxi, and the phones that feed it

Every new character gets one free taxi ride out of the spawn room, to any
place they know: a start point, or a phone found by any of their earlier
characters. The more phones a player has used, the more places the next
character can start from. Heading far out without finding a phone raises
the stakes; finding one lowers them. The picker says so: "Keep an eye out for
pay phones".

**Fast travel** (`TaxiFastTravel`, off by default) turns the phones into a
network. "Call a taxi" on a known phone opens the same picker, listing only
the other phones the player knows, with the fare on the Go button:
`TaxiCentsPerSquare` (1) per square in a straight line, never less than
`TaxiMinimumFare` (100, so $1.00), paid from PhunMart's change. With both at
0 the taxi is free and PhunMart is not needed; otherwise a fare with no
PhunMart installed is refused. No taxi comes with a zombie within
`TaxiZombieRadius` (6). The fare is charged only once the move has been
accepted.

**Nobody is ever taken into somebody else's safehouse**, by the first ride or
a taxi. It is checked against the claim list before the move, so a traveller
simply stays where they are and, for a new character, keeps their choice.
Members may ride home.

## Player pay phones

A player with Electricity 4 crafts a **Pay Phone Kit** (screwdriver, 5
electronics scrap, 2 electric wire, a sheet of metal, 4 screws). "Install pay
phone" on a square puts one there, facing them, after a short action. The
server checks everything first, and a refusal leaves the kit in hand:

- `AllowBuiltPoints`, and at most `BuiltPointLimit` (5) standing per player.
- At least `BuiltPhoneDistance` (50) squares from any other phone of ours.
- Indoors is fine. Somebody else's safehouse is not; your own is, since
  nobody but its members can ride there anyway.
- The phone's square and the one in front have floor and nothing solid.

The builder knows their phone at once. Everybody else finds it the usual way,
and players cannot pick it up, move or smash it. "Take down your pay phone"
removes it and gives the kit back. A built phone lives in the world's ModData,
so a wipe takes it; an admin can **Store** one to keep it.

## Where the truth lives

The unlock list is per **player**: one record per account in global ModData,
keyed by username on a server and by the local player slot in single player.
An unlock is only worth anything when choosing where to wake up, and that is
the next character's choice, so a list kept on the character would die with
the one who earned it. A character from an older version that still carries
a list in its modData has it folded into the account once, and cleared.

`Core.unlocked` is a server side **cache** of that, rebuilt on login, so a
lookup does not reach into ModData every time somebody moves. The
record is the truth and the cache is the copy; `Tests/run.sh` refuses a second
write site, because a copy maintained in two places is a copy that disagrees
with the truth, which reads as a player losing an unlock they can see they
have.


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

A new character is put in the room by the server the first time it sees them,
whatever the vanilla spawn selector said: a free slot if there is one, and a
share of an occupied one if not, so one spawn room is enough for a server.
There is no "Step outside"; the taxi is the way out. With **Wake Up Indoors**
off, or no room to be had, the character is placed at the last point the
player chose, or a start point they know, and that is their one choice used.

## The admin editor

An admin or moderator opens the **Spawn point editor** from the admin panel,
or from the debug menu in single player. It lists every registered point,
found or not, with its region, how it is found, where it is and how far it is
from you (nearest first), beside the whole map. Select one to see it, then:

- **Go there** ports you through `PhunInteriors.sendTo`. It does not unlock
  the point, set your last choice or use up a new character's choice.
- **Rename** changes what players see. The id never changes, because it is
  what every account's unlock list stores. The new name is kept in
  `PhunSpawn.json` (below) and applied whenever the point registers, so it
  survives a restart and a wipe, and it reaches a player the next time they
  open their list.
- **Reset name** puts back the name the point was registered with.
- **Keep** / **Release** on a pay phone. A kept phone is in the next world
  after a wipe. Released, it stays where it is but is not carried over.
- **Found by** / **Remove** on a point an admin added: change whether it is
  known from the start, found by exploring or only granted, or take it out.

## Setting a world up: PhunSpawn.json

An admin can walk the map and set up points once, for this world and every
world after it. Turn on admin mode (the movables or build cheat), then right
click, **Spawn point setup**:

- **Add phone and spawn point here** puts one of our phones on the clicked
  square, facing you, and keeps it. Stand where a character should wake up
  and click the square beside you: the spawn point is in front of the phone,
  which is where you are standing. Greyed out if you click your own square.
  Offered only where there is no phone yet.
- **Add just spawn point here** asks for a name and adds a point on the
  clicked square, found by exploring until the editor says otherwise.
- **Store this payphone**, on any pay phone. A vanilla one is swapped for ours
  on the spot, whatever its roll said.

Both are written straight away to `PhunSpawn.json` in the server's Lua folder
(`Zomboid/Lua/`, beside `PhunInteriors.json`), along with every rename. That
folder is not part of the save, so a wipe leaves it alone. In the new world
the points register at boot, and each kept phone is put back the first time
its square loads, replacing the vanilla phone standing there if there is one.
A kept phone that goes missing is put back the same way; release it first to
be rid of it. In single player the menu is only offered in debug mode.

The file is meant to be read and hand edited, and copying it to another
server copies the setup:

```json
{
  "version": 1,
  "points": {
    "phun.spawn.custom.10608_9698_0": {
      "label": "Muldraugh - Gas station", "region": "Muldraugh",
      "x": 10608, "y": 9698, "z": 0, "discovery": "start"
    }
  },
  "phones": {
    "11702_6890_0": { "x": 11702, "y": 6890, "z": 0, "facing": "E" }
  },
  "labels": { "phun.spawn.westpoint.motel": "The Motel" }
}
```

- A point's `x, y, z` is where the character wakes up. `discovery` is
  `start`, `explore` (the default) or `granted`. A point with the id of a
  shipped one replaces it, which is how a placeholder's square gets fixed
  without code.
- A phone's `x, y, z` is **the phone's own square**, and `facing` (E, S, W or
  N) puts the character on the square in front of it.
- An entry that is wrong is left out and named in the server log. The rest
  still count.

Changes made in game write the file at once, so a hand edit made while the
server runs is **overwritten** by the next one unless it is read in first:
`PhunSpawn.admin("reload")`. A file that does not parse is left alone: nothing
is written to it until it reads again.

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
  media/lua/shared/PhunSpawn/    core, tools, points, phones, phone_guards, taxi,
                                 interiors, defaults
  media/lua/server/PhunSpawn/    unlocks, placement, phone_swap, store, rides,
                                 building, server_{commands,events}
  media/lua/client/PhunSpawn/    client_{main,commands,context,events,phone,admin}
  media/lua/client/PhunSpawn/ui/ picker, editor, map_panel, list_panel, ui_utils
  media/lua/shared/Translate/EN/ ContextMenu, IG_UI, Sandbox, ItemName, Recipes (.json)
  media/scripts/                 PhunSpawn_Items.txt (the kit and its recipe),
                                 PhunSpawn_Sounds.txt

Tests/run.sh              syntax check, static checks and specs
Tests/lua/stubs.lua       PZ globals, faked just enough to load
Tests/lua/points_spec.lua the registry, the sort, discovery and the payload
Tests/lua/store_spec.lua  PhunSpawn.json: the wipe round trip, bad files,
                          kept phones
Tests/lua/taxi_spec.lua   near discovery, fares, rides, safehouses,
                          building and taking down phones
Tests/root/PhunSpawn/     overlay carrying the test id, applied by deploy.cmd
```

The specs load PhunInteriors' `json.lua` from a checkout beside this one
(`../PhunInteriors`), or from wherever `PHUNINTERIORS` points.
```

## Verify before you claim anything works

```bash
bash Tests/run.sh
```

That parses every lua file with LuaJIT, runs six static checks and then the
specs. The static checks exist because each catches a bug class LuaJIT cannot
see:

- no function shadowing a field declared on the `PhunSpawn` table in
  `core.lua`, which silently replaces it at file load time,
- no writer of the unlock cache other than `unlocks.lua`,
- no local redeclared at the top level of one function (`Tests/shadow.pl`),
- no em dashes anywhere,
- nothing global but `PhunSpawn`,
- every translation file parses as JSON.

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

- **Nothing in the taxi or player phones has run in game.** Written and
  covered by `Tests/lua/taxi_spec.lua` as far as it goes without squares; see
  CLAUDE.md, Known gaps 4, for what is unproven.
- **The picker has never been opened in game.** It is written: cities on the
  left, which open to show their points and fit the map to them, and the
  player's own map on the right with a pin per known point. A new character
  gets the whole map, since theirs is still blank. A player reaches it as the
  taxi: **Take taxi ride** on any taxi tile (`phuninteriors_02_0` to `_39`),
  which stand in the spawn room. An admin in admin mode gets **Spawn points**
  on any right click instead. The green "Go" button works **once**, for a new
  character, so it is a choice and not fast travel; after that the picker is
  a map. An admin on a server, or anyone in single player debug mode, can use
  it any time. It ignores a point's `room`, does
  not check that the spawn square is free, and has no joypad support.
- **Nobody is put in the arrival room yet.** `server/arrival.lua` waits on
  `PhunInteriors.enterRoom`, which is not in PhunInteriors yet; until it is,
  a new character is placed at their fallback point. The landing square the
  vanilla selector collapses to is not chosen, so the selector still shows.
- **The arrival room's `locations`.** The room registers with no stamps,
  because there is no map yet. A room with no stamps allocates nothing, which
  is the honest state of affairs.
- **The shipped points are placeholders.** Three vanilla coordinates that need
  checking against the map before they ship: a spawn point on a solid square
  drops a new character into geometry and nothing here can tell.
