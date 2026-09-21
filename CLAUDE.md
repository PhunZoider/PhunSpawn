# PhunSpawn

Project Zomboid **B42** mod. Spawn points that are earned rather than listed:
a character starts knowing a few and finds the rest by walking the map, and a
new character wakes up in an off grid room rather than on a kerb. SP and MP
share one code path.

Author: UburGeek. Part of the Phun mod family (PhunLib, PhunCure, PhunLewt,
PhunZones, PhunInteriors, PhunMart2, PhunHub, PhunServer2...). GitHub org:
`PhunZoider`.

## Status

**Scaffolding. Nothing has run in game.** `Tests/run.sh` is green, which is
real verification of the registry and the unlock logic and no verification at
all that PZ agrees. What exists is the registry, the unlock bookkeeping, the
dispatch layer, the context menu, the picker (see Known gaps 5) and the
translations. What does not is
listed under "Not built" in README.md, and each one is marked `TODO` at the
place it belongs.

The sibling mod to read before changing anything here is **PhunInteriors**.
Its `CLAUDE.md` carries the B42 API table this family has paid for, and none
of it should be re-derived.

## Verify before you claim anything works

```bash
bash Tests/run.sh
```

Parses every lua file with LuaJIT, then runs four static checks and the specs
in `Tests/lua/`. Each static check catches a bug class LuaJIT cannot see:

- **namespace**: no function shadowing a field declared on the `PhunSpawn`
  table in `core.lua`. A `function Core.points()` helper would *replace* the
  registry table at file load time, silently, and the first registration would
  index a function. That has happened in this family.
- **unlocks**: no writer of `Core.unlocked` other than `unlocks.lua`. It is a
  cache of the character record, and a copy maintained in two places
  disagrees with the truth.
- **shadows**: no local redeclared at the top level of one function
  (`Tests/shadow.pl`). LuaJIT parses one happily and the damage shows up
  somewhere else entirely.
- **dashes**: no em dashes. See House style.

LuaJIT cannot catch API misuse. PZ globals do not exist outside the game, and
LuaJIT accepts `next()` and `loadstring`, neither of which B42 exposes.

`Tests/lua/stubs.lua` fakes the handful of globals the files touch while
loading. It is **not** a mock of the game: anything needing an `IsoGridSquare`
is tested in game or not at all. Add to it when you change registry or unlock
logic; do not try to grow it into a simulator.

Deployment is VS Code `emeraldwalk.runonsave` (see `.vscode/settings.json`),
which runs `deploy.cmd` on every save and builds four trees: the playable mod,
the test id variant `PhunSpawnTest`, and Workshop staging for each. `xclude`
is the xcopy exclude list.

## Layout

Standard Phun conventions, mirroring PhunInteriors and PhunCure2. Everything
ships under `common/`. There is no root `mod.info` and no versioned (`42.x/`)
folder.

```
Contents/mods/PhunSpawn/common/
  mod.info                  id=phunspawn, versionMin=42.0.0, require=phuninteriors
  media/sandbox-options.txt
  media/lua/shared/PhunSpawn/   core, tools, points, interiors, defaults
  media/lua/server/PhunSpawn/   unlocks, placement, server_{commands,events}
  media/lua/client/PhunSpawn/   client_{main,commands,context,events}
  media/lua/client/PhunSpawn/ui/  picker, map_panel, list_panel (vendored),
                                  ui_utils
  media/lua/shared/Translate/EN/  ContextMenu.json, IG_UI.json, Sandbox.json

Tests/run.sh               syntax check, static checks and specs
Tests/lua/stubs.lua        PZ globals, faked just enough to load
Tests/lua/points_spec.lua  the registry, the sort, discovery and the payload
Tests/root/PhunSpawn/      overlay carrying the test id. The path must mirror
                           the live mod folder or the overlay silently does
                           nothing.
```

House style, taken from PhunInteriors and PhunCure2:

- `core.lua` holds `name`, `consts`, `commands`, `events`, `settings`,
  `modules`.
- `*_commands.lua` **returns** a `Commands` table; `*_events.lua` dispatches
  into it.
- Server files open with `if isClient() then return end`, client files with
  `if isServer() then return end`. In SP both are false, so both load.
- Everything hangs off the `PhunSpawn` global. **No other globals.**
- **And nothing may be hung off `PhunSpawn` under a name `core.lua` already
  declares.** `Tests/run.sh` refuses it.
- Settings cached via `Core.getOption` and refreshed on `EveryTenMinutes`.
- **No em dashes. Anywhere.** Not in this file, not in code comments, not in
  commit messages, not in anything written for a player to read, and not in a
  reply. Where one would go, use `--`, or recast around a comma, a colon or a
  full stop. `Tests/run.sh` checks.

## Architecture, and why

**One code path for SP and MP.** `Core.dispatch` / `Core.respond` check
`Core.isLocal` and either round-trip through `sendClientCommand` or call the
handler directly. Never write a separate SP implementation: two halves drift.

**The character record is the truth, and the cache is a copy.** The unlock
list lives in player modData, because `IsoPlayer.save` reaches
`IsoMovingObject.save`, which writes the modData `KahluaTable` into the
character record. So an unlock survives a restart, a wipe of
`global_mod_data.bin`, and anything our own store could lose. `Core.unlocked`
is the server side cache, rebuilt on login.

It is per **character** and cannot be anything else without changing the
mechanic: discovery is the point, and an account wide list hands the second
character a map that is already solved.

**A starter is granted on read, not stamped once.** So a point added to the
start set in a later version reaches existing characters and there is no
migration to write.

**Discovery defaults to `explore`, never to `start`.** The safe default is the
one that gives nothing away, so a point meant to be known has to say so. Same
shape as PhunInteriors' rule that a position must have no default: a wrong
default fails *plausibly* rather than loudly.

**Where a point is, is data, not arithmetic.** `locations`-style arithmetic
was refused here before it could be written, for the reason PhunInteriors
removed its own: a set laid out on a grid is three lines shorter and puts half
the points in the river. A genuinely regular set is a `for` loop in the caller.

**A removed point is filtered on read, not deleted from everybody.** So
`removePoint` does not walk every character's list, and taking a point set out
temporarily and putting it back costs nobody their exploring.

**Reverse indexes rebuild lazily**, on the first read after any registration.
That is what lets a third party register from any vanilla hook, including one
that fires long after our boot sequence. The consequence is that **nothing may
warn about a missing link at boot**: at boot it cannot tell "not registered
yet" from "the mod that owns it is not installed". Say it at the point of
refusal instead.

**Discovery is swept on a timer, not on every movement update.** A point is a
place you walk to and stay near for a moment, not a tripwire you can sprint
through, and running a sweep over every online player at 60Hz to notice
something that changes once a session is how a mod becomes the reason a server
is slow.

**The payload honours `ShowUndiscovered` server side.** A client handed the
coordinates can draw them whatever the option says, so an option enforced only
in the UI is not enforced at all.

**PhunInteriors is a hard dependency** (`require=phuninteriors`, and
`phuninteriorstest` for the test id). This mod uses its off grid room, its
map instancing, its tiles and textures (see `Docs/map.md`) and its way of
moving a player, so there is no working mode without it. Older code and
comments that guard for it being absent are from when it was a soft hook.

**Moving a player is `PhunInteriors.sendTo`, never a teleport of our own.**
A bare teleport out of a room leaves PhunInteriors believing the player is
still in it: occupancy, lease, leash and the client's "Step outside" all stay
behind. `sendTo` is PhunInteriors' own exit with the destination replaced,
and it pushes zombies off the landing square once the player's client
reports the arrival. It lives in PhunInteriors' `server/transit.lua` and is
covered by that repo's `sendto_spec.lua`.

The room registers with **no binding**. A PhunInteriors binding says which
vehicles or objects may *lease* a room, and nothing leases this one: a spawn
room is entered by being a new character, which is a different question from
the entitlement machinery and must not be squeezed into it.

**Register from `Events.OnInitGlobalModData`, never from one of PhunInteriors'
own events.** `Events` is a plain Kahlua table with no metatable, so a key
exists only once `LuaEventManager.AddEvent` has been called for it. If our
file loads first, `Events[theirs]` is nil and the `.Add` throws, and firing
later cannot rescue a listener that was never attached. `OnInitGlobalModData`
always exists and fires everywhere, including on a dedicated server;
`OnGameStart` is triggered only from `zombie.gameStates.IngameState`, which a
dedicated server does not have.

## Known gaps

1. **Nothing has run in game.** The whole mod. The first thing to watch is
   whether a server side write to player modData persists on a **dedicated**
   server: it is settled from the jar for PhunInteriors' entrance key and
   nothing has confirmed it for ours. If the client's copy wins, every unlock
   comes back empty after a rejoin, silently.
2. **The shipped points are placeholders.** Three vanilla Muldraugh, West
   Point and Riverside coordinates that have not been checked against the map.
   A spawn point on a solid square drops a new character into geometry and
   nothing here can tell.
3. **The arrival room ships no `locations`.** A room with no stamps registers
   and allocates nothing, which is the honest state of affairs rather than a
   failure. Fill it once the cells exist, reading origins out of the lotpacks
   with PhunInteriors' `Docs/tiles.pl` rather than off a grid, and check with
   `Docs/roomcheck.pl`.
4. **Built points are a stub, and the constraint is already known.** Object
   modData does **not** survive a pickup reliably, and whether it does depends
   on which tile was clicked. So either the marker refuses to be picked up, or
   a built point must not depend on its modData surviving one. See the tent
   pickup rows in PhunInteriors' API table before designing this.
5. **The picker is written and has never been opened.** `client/.../ui/`:
   `picker.lua` is the window and an accordion list (click a city to open it
   and fit the map to it), `map_panel.lua` is a bare `UIWorldMap` set up call
   for call from `ISWorldMap:initDataAndStyle`, and `list_panel.lua` is
   PhunMart2's panel vendored via PhunInteriors' copy. `form_panel.lua` was
   **not** vendored because nothing here is a form; if one is ever added, the
   trap is that `FormPanel` calls `self._onApply(self)` and passes the
   **form**, not a values table. Unproven in game, in order of risk:
   `uiToWorldX(x, y, zoom, cx, cy)` as the zoom-to-fit probe, `transitionTo`,
   pins drawn in `render` (not `prerender`) landing above the map, and the
   list column headers. The spawn button is once only per character
   (`server/.../placement.lua`, stamped in modData under `spawnedKey`), and
   rests on the same unproven dedicated server modData write as gap 1.
   `point.room` is ignored, the spawn square is not checked for being free,
   and there is no joypad support.
6. **`icon.png` and `poster.png` are missing.** `mod.info` names both, and
   `Tests/root/PhunSpawn/common/` needs its own pair for the test id.
7. **`workshop.txt` has an empty `id=`.** Fill on first publish.
