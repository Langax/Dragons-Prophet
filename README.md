# Dragon's Prophet - Lua Code Templates

Welcome to my **Dragon's Prophet Lua Code Templates** repository  
This repo contains modular, ready-to-use Lua code designed to extend and customize gameplay in *Dragon's Prophet*. These templates serve as foundations for creating new game functions, features, or systems using Lua scripting.

this repo is built to grow and scale with creating new gameplay mechanics, improving UI interactions, or tweaking core logic.

---

## 📁 Repository Structure

All Lua files in this repo are standalone modules focused on specific systems or additions. Each file is documented and designed for easy integration into your *Dragon's Prophet* setup.

Current files:

### ✅ 'PvP Arena.lua'

A basic setup for implementing A 1v1 **PvP Arena** functionality. (Possible to expand in the future to XvX)

#### Features:
- Self‑service queue system – ny_JoinQueue adds players to a queue, offers instant opt‑out, and pair‑matches the first two ready contenders.
- Ready‑check dialog – both players must click Yes within 20 s; auto‑handles declines, disconnects, and re‑queues the survivor.
- Seamless arena deployment – cleans old PvP buffs, then teleports fighters to mirrored sanctuary spawn points (cross‑zone ChangeWorld when needed).
- Guild/Union isolation – temporarily rewrites Guild ID & Union ID per fighter so allied mechanics cannot interfere, restoring values post‑match.
- Pre‑fight pause & countdown – applies a short “pause” debuff, shows 10 s prep clock, then a 5‑minute combat timer with on‑screen clocks for both players.
- Battle supervisor coroutine – tracks deaths or timeout, declares winner/loser, logs results, pays configurable rewards (15/5 battleground badges), and clears buffs.
- Spectator mode – one‑click teleport to the Arena, auto‑gives spectator leave item and three prevention buffs, item returns the player to the lobby and clears buffs.
- Anti‑grief safeguards – combatants can’t leave via the spectator item, logout while fighting forces an instant timeout loss.
- Clean teardown – resets faction IDs, closes clocks, deletes placeholder NPC, and toggles global State flags so the next match can start immediately.

#### Usage:
Drop the file into your Lua scripts folder and adjust your game logic to include the arena system.
Set flag positions inside of the Arena Zone you wish to use, and adjust SANC_P1_POS or SANC_P2_POS to make use of in-guild fights.
Add Collision Boxes for ny_JoinQueue_Start() and ny_PvP_Spectate().
For full functionality, add functions such as ny_Logout() into the LuaEvent_Logout() to ensure cleanup on player disconnect.


### ✅ 'Backpack & Shardbag.lua'

#### Features:

#### Usage:


### ✅ 'Custom Dungeon.lua'

An example setup on adding new Custom Dungeons into Dragon's Prophet (Possible to expand further, or add to other Dungeons in the future)
This is not a finalized system, and has not been balanced for player use.

#### Features:
- Version‑aware entry point – single ny_SpiderQuest() dispatcher spins up Path One or Path Two by version flag, making future variants pluggable.
- Centralised state table – keeps all transient data (room ID, doors, packs, kill count, combat flags) in one mutable structure for easy debugging.
- Flag‑based spawning – doors, mobs, placeholders and bosses are all created via numeric flag/offset pairs, for easy adaptability.
- Reusable helpers – ny_SetStaticDoor, ny_SetAggressiveMob, ny_SpawnDoor, ny_SpawnPack abstract away verbose mode/flag logic.
- Wave‑gated progression – each path tracks kill totals (PATH_ONE_KILL_GOAL, PATH_TWO_KILL_GOAL) and automatically deletes doors once thresholds are met.
- Boss encounter supervisor – separate coroutine monitors leashing, reset, combat start & finish, and auto‑seals / unlocks doors.
- Anti‑cheat buff logic – boss gains an un‑purgeable buff unless players have legitimately cleared the required wave objective.
- Minimal AI – lightweight ny_CrawlerBossAI() shows how to hook custom behaviour via register values, simple to expand upon.
- Log Output: Console prints for dungeon state and transitions for easier debugging.
- Entirely custom Ai example on the 2nd path Boss

#### Usage:
Drop the file into your Lua scripts folder and adjust your game logic to include the system.
Set flag locations into the required Dungeon for Monster, Boss and Door Spawns.
Add a Collision Box by the entrance to call the Entry Point ny_SpiderQuest() and include the Collision Box number as the CollisionBoxID to disable it after use.
