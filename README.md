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
- Initializes arena instance logic
- Manages player registration and match state
- Supports match outcome tracking and event hooks
- Easily extendable for ranking, rewards, or advanced mechanics

#### Usage:
Drop the file into your Lua scripts folder and adjust your game logic to include the arena system.
For full functionality, add functions such as ny_Logout() into the LuaEvent_Logout() to ensure cleanup on player disconnect.

### ✅ 'Backpack & Shardbag.lua'

#### Features:

#### Usage:


### ✅ 'Custom Dungeon.lua'

#### Features:

#### Usage:
