# timijshax

**Recovery release:** Runtime has been returned to the first renamed version after startup failures. Privacy removals and the verified theme-property fix remain. The redesigned console, ingredient filters, spawn memory, and activation voice are temporarily inactive. Their code/history is retained while startup is verified.

A renamed fork of [Hydroxide](https://git.fable.bz/zyu/hydroxide), maintained in [sitnug/timijshax](https://github.com/sitnug/timijshax).
Original Hydroxide authors retain credit for their work. This fork remains licensed under AGPL-3.0-or-later; see [LICENSE](LICENSE).

Changes made on 2026-09-24: renamed the project and in-game window titles, moved module and dependency loading to this GitHub repository, corrected Battlegrounds dependency paths, and updated its server-hop loader. Existing configuration folders and internal identifiers remain compatible with Hydroxide. Automatic upstream analytics and Stella collection were removed during the privacy audit.

## Usage

Run this in your Roblox executor while in a supported game:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sitnug/timijshax/main/loader.lua?nonce=" .. tostring(math.random()), true))()
```

The loader selects Rogue Lineage or Rogue Lineage Battlegrounds automatically.

## timijshax interface

The Command Console redesign uses a horizontal module dock, full-width workspace, original bundled icons, graphite panels, lime accents, and monospace typography. Narrow windows stack both settings columns into one scrollable list. Search, window resizing, saved options, and keybinds are retained. Choose **timijshax Command** in **Profiles** if a previously saved theme overrides the palette.

In Rogue Lineage, open **Intel → Ingredient ESP** to search and select ingredient types. The type list supports A–Z or Z–A order, Select all, and Clear. All 26 recognized types plus Unknown are available; clearing the selection hides every ingredient. Selections save with your configuration and apply to newly spawned ingredients. This filter only affects ESP, not automatic pickup.

## Startup audio and trinket spawn locations

The loader announces “timijshax activated” using a bundled robotic voice. Playback requires executor support for local files and `getcustomasset` or `getsynasset`; audio failure does not block loading.

In Rogue Lineage, **Intel → Trinket Spawn Locations** can highlight known spawn locations even after pickup, independently of Trinket ESP. Observed positions are cached per place when file access is available. These positions are observations, not a complete verified spawn map. The optional **Spawn folder path** highlights all parts in a verified, client-visible spawn container, including empty ones. **Copy spawn candidates** copies possible paths for inspection; candidate names alone do not prove they are trinket spawns. Server-only or undiscovered positions cannot be shown without a map or client-visible spawn parts.

### Learning across servers

Spawn memory now records each location's observation count, first/last-seen timestamps, and server visits. Locations within half a stud merge to tolerate small coordinate differences. Repeated callbacks for the same live object do not increase counts; re-executing can count a still-present trinket as another observation, so these are not spawn-rate estimates. Memory loads automatically per PlaceId, saves every 15 seconds, on teleport, and on unload, and keeps a previous-save backup. Old coordinate caches migrate automatically. Use **Save memory now** before abruptly closing your executor.

Files live in your executor's local workspace as `timijshax-spawns-<PlaceId>.json` and `.json.bak`. Learning works with markers hidden. It requires the same executor storage to carry across runs; it does not synchronize across devices or users. Memory is limited to 3,000 locations per place and does not claim to discover unobserved or server-only spawn points.

### Read-only Explorer

Open **Intel → Trinket Spawn Locations → Open read-only Explorer**, or execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sitnug/timijshax/main/explorer.lua", true))()
```

Search for `spawn`, `trinket`, or `loot` and press Enter. Select a row to inspect it, use `>` to browse children, and **Copy selected path** to share a path for inspection. Names are only clues; verify that the parts really are trinket spawn points before using a folder. The Explorer only reads client-visible objects.

### UI recovery

If the redesigned UI fails in your executor, set `getgenv().timijshax_classic_ui = true` before running the loader to use the previous layout. This keeps the privacy fixes, ingredient filters, and spawn memory. Set it to `false` to return to the Command Console. The loader reports download/compilation/startup failures to the local console and refreshes stale official-release pins.

## Games Supported

| Game | Script | Lines |
|------|--------|-------|
| Rogue Lineage | `ROGUE/rogue_ui.lua` | ~27,000 |
| Rogue Lineage Battlegrounds | `ROGUE_BATTLEGROUNDS/rlb.lua` | ~14,000 |

---

## Rogue Lineage

The flagship module. Full-featured combat, automation, visuals, and botting system.

### Combat
- **Auto Parry** - Automatic perfect blocking with ping adjustment, custom delay, FOV angle, ability-specific parry (Viribus, Owlslash, Shadowrush, Verdien, Grapple), semi-blatant mode
- **Silent Aim** - Adjustable FOV, ignore blocking players, visibility checks
- **Combat Utilities** - No Stun, No Confusion, Perflora Teleport, Attach to Back, Better Mana Charge, Auto Misogi, Anti Backfire, Hold Block

### Visuals
- **Player ESP** - Name, Box, Health bars, Tags, Intent detection, Mana display, Racial identification, Fade with distance
- **Chams** - Player/Friendly/Low Health/Aimbot/Racial chams with pulse effects and occlusion
- **Trinket ESP** - Filterable by type with area labels and range control
- **World ESP** - Ore ESP (Mythril, Copper, Iron, Tin), Ingredient ESP, NPC ESP, Shrieker/Fallion detection
- **Mana Overlay** - Real-time mana visualization
- **Better Leaderboard** - Enhanced player list with additional info

### Automation
- **Trinket Bot** - Fully autonomous trinket farming with path recording, gate traversal, multi-server rotation, emergency escape (player detection, moderator avoidance), smart serverhop logic, loot tracking with Discord webhooks
- **Day Farm** - Automated day progression with player avoidance, moderator detection, dangerous item detection (Pebble/Perflora), configurable range, day goal targeting
- **Auto Pickup** - Auto Trinket, Auto Ingredient, Auto Weapon, Auto Bag (with range visualization), Auto Resurrection
- **Auto Craft** - Automated potion/weapon crafting with configurable delays
- **Macro System** - Record and replay custom action sequences with per-macro toggles
- **Artifact Stream** - Public Discord webhook feed of artifact spawns for community use, separate from personal logging

### Botting
- **Path System** - Record walk paths with gate points, save/load paths, visualize points
- **Smart Serverhop** - Join largest/smallest/oldest/newest servers, server history tracking, persistent configs across hops via MemStorageService
- **Emergency Systems** - Player proximity detection with configurable gate escape or path traversal, moderator detection with multi-encounter tracking, dangerous item detection, shrieker avoidance
- **Loot Tracking** - Per-session item collection with inventory value calculation, Discord webhook reporting on serverhop

### World
- **Freecam** - Detached camera with speed control
- **Environment** - Fullbright, No Fog, Time control, No Blindness/Blur/Sanity effects, Temperature Lock
- **Movement** - Flight, Noclip, Speed Boost, Better Flight, No Fall Damage, No Kill Bricks

### Exploits
- Anti-Globus, Fling, Force Field, Instant Mine, Inn Teleport, AA Bypass
- Character customization (face, clothing, skin, accessories, outfit presets)

---

## Rogue Lineage Battlegrounds

PvP-focused module inheriting Rogue Lineage's combat systems, optimized for arena gameplay.

### Combat
- Auto Parry with all parry settings (ping adjust, FOV, ability-specific, semi-blatant)
- Silent Aim with FOV control
- Full combat utilities (No Stun, No Confusion, Perflora Teleport, Hold Block, Anti Backfire)

### Visuals
- Player ESP with full suite (Name, Box, Health, Tags, Intent, Mana, Racial)
- All chams variants (Player, Friendly, Low Health, Aimbot, Racial)
- Mana Overlay, Better Leaderboard, Shrieker Chams, NPC ESP
- Legit Intent display

### World & Movement
- Freecam, Flight, Noclip, Better Flight
- Fullbright, No Fog, Time control, No Blindness/Blur/Sanity
- Fling, Invisible Cam

### Other
- Full macro system with save/load
- Auto Dialogue, Auto Bard, Anti AFK
- Config management with server join utilities

---

## Project Structure

```
timijshax/
  ROGUE/
    rogue_ui.lua              -- Main Rogue Lineage script (~27,000 lines)
  ROGUE_BATTLEGROUNDS/
    rlb.lua                   -- Rogue Battlegrounds script (~14,000 lines)
  DEPENDENCIES/
    Library.lua               -- UI framework
    SaveManager.lua           -- Config save/load
    ThemeManager.lua          -- UI theming
    Chatlogger.lua            -- Chat logging module
```

## Privacy

Automatic Stella player/server collection, upstream device/executor analytics, and automatic chat/error reporting have been removed. Optional webhooks only send when a destination is configured; username inclusion requires an explicit opt-in. Do not put account cookies, credentials, or webhook URLs into source files.

Spawn history, saved configs, friends lists, and chat logs are executor-local files. This repository uses an explicit source-file allowlist and excludes runtime data. Nothing in the spawn-memory implementation uploads that data to GitHub. GitHub still receives normal requests for public script/assets, and Roblox services receive requests needed for game features. The optional Roblox Account Manager integration communicates with your local manager; those account-management features and third-party executors are outside this repository audit.

Public source and the repository owner's GitHub username remain visible. A history rewrite cannot recall copies previously downloaded by others or guarantee removal of cached commit pages.

## Dependencies

- Roblox executor environment with `cloneref`, `getconnections`, `hookfunction`, `fireclickdetector`, `firesignal` support
- HTTP request capability for Discord webhook integration
- `queueteleport` / `queue_on_teleport` for persistent execution across serverhops
- `MemStorageService` for state persistence across teleports

---

## License

This project is licensed under the [GNU Affero General Public License v3.0 or later](LICENSE) (`AGPL-3.0-or-later`).

If you distribute a modified version of Hydroxide, you must make the corresponding source code available under the terms of the AGPL and clearly state any changes you have made. The AGPL also requires modified versions made available for users to interact with over a network to provide those users access to the corresponding source code.

See the [LICENSE](LICENSE) file for the full license terms.

---

*Development is slowed but not dead. Feel free to open issues, submit PRs, or fork and build your own version.*

---

## Acknowledgements

Repository setup assisted by [Claude Code](https://claude.ai/claude-code).
