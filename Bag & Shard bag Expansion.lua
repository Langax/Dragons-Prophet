--==============================================================
--  Bag & Shard-Bag Expansion
--  Current Version: 2.0
--  Made by Lang
--==============================================================

-- ─── Constants ───────────────────────────────────────────────
local BACKPACK_PRICE_GOLD     = 1000000
local BACKPACK_STEP_SLOTS     = 40
local BACKPACK_MAX_SLOTS      = 1000          -- hard cap; change as needed

local SHARD_BASE_PRICE_GOLD   = 500000
local SHARD_STEP_SLOTS        = 32
local SHARD_TIER1_MAX         = 2048          -- flat price up to this size
local SHARD_MAX_SLOTS         = 4096          -- hard cap

local DIALOG_POLL_MS          = 10            -- Sleep step
local DIALOG_TIMEOUT_STEPS    = 100           -- 100 * 10ms = 100s

-- ─── Helpers ────────────────────────────────────────────────
local function ny_Debug(msg) DebugMsg(0, "[Bag] "..msg) end

local function ny_SendTargetMsg(player, text)
    ScriptMessage(player, player, EM_ScriptMessageSendType_Target, EM_ClientMessage_Chat,  text, 0)
    ScriptMessage(player, player, EM_ScriptMessageSendType_Target, EM_ClientMessage_Quest, text, 0)
end

local function ny_AskYesNo(player, prompt, intialpos)
    DialogCreate(player, EM_LuaDialogType_YesNo, prompt)
    DialogSendOpen(player)
    for _ = 1, DIALOG_TIMEOUT_STEPS do
        local result = DialogGetResult(player)
        if result == 0 then DialogClose(player); return false
        elseif result == 1 then DialogClose(player); return true end
        if GetDistance(Player, initialpos) >= 10 then DialogClose(player); return false
        Sleep(DIALOG_POLL_MS)
    end
    DialogClose(player)
    return false
end

-- ─── Backpack Expansion ─────────────────────────────────────
function ny_BackpackExpansion()
    BeginPlot(OwnerID(), "ny_BackpackExpansionOpen", 0)
end

function ny_BackpackExpansionOpen()
    local me   = OwnerID()
    local gold = ReadRoleValue(me, EM_RoleValue_Money)
    local bag  = ReadRoleValue(me, EM_RoleValue_BodyCount)
    local initialpos = Dinaya_RolePos(me)

    if bag >= BACKPACK_MAX_SLOTS then
        Lua_SysWarning(me, "I can't expand your bag any further.")
        return
    end

    local prompt = ("Increase your bag size by %d slots for %d gold?"):format(BACKPACK_STEP_SLOTS, BACKPACK_PRICE_GOLD)
    if not ny_AskYesNo(me, prompt, initialpos) then return end

    if gold < BACKPACK_PRICE_GOLD then
        Lua_SysWarning(me, "You need more gold! Requires "..BACKPACK_PRICE_GOLD..".")
        return
    end

    WriteRoleValue(me, EM_RoleValue_Money, gold - BACKPACK_PRICE_GOLD)
    WriteRoleValue(me, EM_RoleValue_BodyCount, math.min(bag + BACKPACK_STEP_SLOTS, BACKPACK_MAX_SLOTS))
    ny_SendTargetMsg(me, "Your bag size has increased!")
end

-- ─── Shard-Bag Expansion ────────────────────────────────────
function ny_ShardBagExpansion()
    BeginPlot(OwnerID(), "ny_ShardBagExpansionOpen", 0)
end

function ny_ShardBagExpansionOpen()
    local me       = OwnerID()
    local gold     = ReadRoleValue(me, EM_RoleValue_Money)
    local shards   = ReadRoleValue(me, EM_RoleValue_MaxProStoneCount)
    local initialpos = Dinaya_RolePos(me)

    if shards >= SHARD_MAX_SLOTS then
        Lua_SysWarning(me, "I can't expand your shard bag any further.")
        return
    end

    -- Pricing: flat up to tier1, then scales gently with current size
    local price = (shards <= SHARD_TIER1_MAX) and SHARD_BASE_PRICE_GOLD or math.floor(SHARD_BASE_PRICE_GOLD * (shards / 1024))

    local prompt = ("Increase your shard bag by %d slots for %d gold?"):format(SHARD_STEP_SLOTS, price)
    if not ny_AskYesNo(me, prompt, initialpos) then return end

    if gold < price then
        Lua_SysWarning(me, "You need more gold! Requires "..price..".")
        return
    end

    WriteRoleValue(me, EM_RoleValue_Money, gold - price)
    WriteRoleValue(me, EM_RoleValue_MaxProStoneCount, math.min(shards + SHARD_STEP_SLOTS, SHARD_MAX_SLOTS))
    ny_SendTargetMsg(me, "Your shard bag has increased!")
end
