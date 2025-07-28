--==============================================================
--  PvP Queue & Arena 
--  Current Version: 2.8.3
--  Made by Lang
--==============================================================

-- ─── Constants ───────────────────────────────────────────────
local PVP_BUFF        = 30001529
local PAUSE_BUFF      = 30012393
local WIN_REWARD      = 15
local LOSE_REWARD     = 5
local CURRENCY_TYPE   = 10
local SPECTATOR_ITEM  = 20012322
local PLACEHOLDER_NPC = 10010269

local SPECTATOR_BUFFS = { 30003223, 30011877, 30012023 }
local LOBBY_POS       = { 45000010, 0 }
local ARENA_P1_POS    = { 45000010, 1 }
local ARENA_P2_POS    = { 45000010, 2 }
local SPECTATE_POS    = { 45000010, 3 }
local PLACEHOLDER_POS = { 45000010, 4 }

-- Teleportation must be handled with ChangeWorld for fights inside the same Guild
local SANC_P1_POS     = { 2, 104, 0, 13, 1151, 300, 180 }
local SANC_P2_POS     = { 2, 104, 0, 13, 1151, -143, 0  }

-- ─── Script‑wide state ──────────────────────────────────────
local State = {
    Queue       = {},
    InQueue     = {},
    InCombat    = false,
    Player1     = nil,
    Player2     = nil,
    Winner      = nil,
    Loser       = nil,
    Placeholder = nil,
    FightTime   = 0
}

-- ─── Utility helpers ────────────────────────────────────────
local function ny_Debug(Msg)                   DebugMsg(0, Msg) end
local function ny_Teleport(Player, Pos) Lua_MK_SetPosByFlag(Player, Pos[1], Pos[2]) end
local function ny_WorldTeleport(Player, Pos) ChangeWorld(Player, Pos[1], Pos[2], Pos[3], Pos[4], Pos[5], Pos[6], Pos[7]) end
local function ny_ArenaClock(Player, Time) ClockOpen(Player, 1, 0, 0, Time, "Dinaya_BaseClock_DoNothing", "Dinaya_BaseClock_DoNothing", "") end


local function ny_Chat(Player, Text)
    ScriptMessage(Player, Player, EM_ScriptMessageSendType_Target, EM_ClientMessage_Chat,  Text, 0)
    ScriptMessage(Player, Player, EM_ScriptMessageSendType_Target, EM_ClientMessage_Quest, Text, 0)
end

local function ny_PvPPlaceholder()
    State.Placeholder = CreateObjByFlag(PLACEHOLDER_NPC, PLACEHOLDER_POS[1], PLACEHOLDER_POS[2])
    SetModeEx(State.Placeholder, EM_SetModeType_Mark,        true)          -- Enable Target Icon
    SetModeEx(State.Placeholder, EM_SetModeType_Move,        false)         -- Enable Movement
    SetModeEx(State.Placeholder, EM_SetModeType_Fight,       false)         -- Enable Combat
    SetModeEx(State.Placeholder, EM_SetModeType_Searchenemy, false)         -- Enable Attack
    SetModeEx(State.Placeholder, EM_SetModeType_Show,        true)          -- Enable Visibility
    AddtoPartition(State.Placeholder, ReadRoleValue(OwnerID(), EM_RoleValue_RoomID))
end

function ny_ClearPvPBuffs(Player)
    SetModeEx(Player, EM_SetModeType_ShowName, false)
    SetModeEx(Player, EM_SetModeType_ShowName, true)
    for _, Buff in ipairs{30001529, 30001530, 30001531, 30003223, 30011877, 30012023} do
        if CheckBuff(Player, Buff) then CancelBuff(Player, Buff) end
    end
end

local function ny_RemoveFromQueue(ID)
    if not State.InQueue[ID] then return end

    for i, Player in ipairs(State.Queue) do
        if Player == ID then table.remove(State.Queue, i); break end
    end

    State.InQueue[ID] = nil
end

local function ny_IsolateGuild(Player, TempID)
    local Original = {
        Guild = ReadRoleValue(Player, EM_RoleValue_GuildID),
        Union = ReadRoleValue(Player, EM_RoleValue_UnionID),
    }
    WriteRoleValue(Player, EM_RoleValue_GuildID,  TempID)
    WriteRoleValue(Player, EM_RoleValue_UnionID,  TempID)
    return Original
end

local function ny_LogTracking()
    local Winner = GetPlayerName(State.Winner)
    local Loser = GetPlayerName(State.Loser)
    DesignLog(State.Winner, 999, Winner.." Won a 1v1 battle against "..Loser)
    DesignLog(State.Loser, 998, Loser.." Lost a 1v1 battle against "..Winner)
end

--──────────────────────────────────────────────────────────────
--                       PUBLIC ENTRY POINTS
--──────────────────────────────────────────────────────────────

-- 1. Player enters the queue
function ny_JoinQueue_Start()  BeginPlot(OwnerID(), "ny_JoinQueue", 0) end

function ny_JoinQueue()
    local Me = OwnerID()

    -- Already Queued -> offer to quit
    if State.InQueue[Me] then BeginPlot(Me, "ny_QuitQueue", 0) return end

    -- Enter Queue
    table.insert(State.Queue, Me); State.InQueue[Me] = true; ny_Chat(Me, "You joined the queue!")
    for _, Player in ipairs(State.Queue) do ny_Debug("Current Queue: "..Player.." in position ".._) end

    -- If not in combat already and two player are ready, start the fight
    if not State.InCombat and #State.Queue >= 2 then
        State.Player1, State.Player2 = State.Queue[1], State.Queue[2]

        -- Ready check dialogs
        DialogCreate(State.Player1, EM_LuaDialogType_YesNo, "An opponent was found! Are you ready to enter the battle?")
        DialogSendOpen(State.Player1)
        DialogCreate(State.Player2, EM_LuaDialogType_YesNo, "An opponent was found! Are you ready to enter the battle?")
        DialogSendOpen(State.Player2)

        for _ = 1, 20 do
            local Result1 = DialogGetResult(State.Player1)
            local Result2 = DialogGetResult(State.Player2)

            ny_Debug("Player 1 Result: "..Result1)
            ny_Debug("Player 2 Result: "..Result2)

            if Result1 == 0 or Result2 == 0 then -- Someone backed out
                DialogClose(State.Player1); DialogClose(State.Player2)
                if Result1 == 0 then
                    ny_Chat(State.Player1, "You left the queue!")
                    ny_Chat(State.Player2, "Your Opponent backed out! Re-entering queue!")
                    ny_RemoveFromQueue(State.Player1)
                else
                    ny_Chat(State.Player2, "You left the queue!")
                    ny_Chat(State.Player1, "Your Opponent backed out! Re-entering queue!")
                    ny_RemoveFromQueue(State.Player2)
                end
                return
            elseif Result1 == -1 or Result2 == -1 then -- Disconnect
                DialogClose(State.Player1); DialogClose(State.Player2)
                if Result1 == -1 then
                    ny_Chat(State.Player1, "You left the queue!")
                    ny_Chat(State.Player2, "Your Opponent backed out! Re-entering queue!")
                    ny_RemoveFromQueue(State.Player1)
                else
                    ny_Chat(State.Player2, "You left the queue!")
                    ny_Chat(State.Player1, "Your Opponent backed out! Re-entering queue!")
                    ny_RemoveFromQueue(State.Player2)
                end
                return
            elseif Result1 == 1 and Result2 == 1 then break end -- Both ready
            Sleep(10)
        end
        DialogClose(State.Player1); DialogClose(State.Player2)
        -- Teleport & buff cleanup
        ny_ClearPvPBuffs(State.Player1); ny_ClearPvPBuffs(State.Player2)
        ny_WorldTeleport(State.Player1, SANC_P1_POS)
        ny_WorldTeleport(State.Player2, SANC_P2_POS)
        ny_RemoveFromQueue(State.Player1); ny_RemoveFromQueue(State.Player2)


        State.InCombat = true
        ny_PvPPlaceholder()
        BeginPlot(State.Placeholder, "ny_InCombatPVP", 0)
    end
end

-- 2. Fight coroutine (runs for player1, but supervises both)
function ny_InCombatPVP()
    local SavedFaction = {
        [State.Player1] = ny_IsolateGuild(State.Player1, 999),
        [State.Player2] = ny_IsolateGuild(State.Player2, 998),
    }

    local P1Dead, P2Dead = 0, 0, 0
    ny_Debug(("MATCH START  P1: %d  P2: %d"):format(State.Player1, State.Player2))
    AddBuff(State.Player1, State.Player1, PVP_BUFF, 1, 10000000)
    AddBuff(State.Player2, State.Player2, PVP_BUFF, 1, 10000000)
    AddBuff(State.Player1, State.Player1, PAUSE_BUFF, 1, 100)
    AddBuff(State.Player2, State.Player2, PAUSE_BUFF, 1, 100)
    ny_ArenaClock(State.Player1, 10)
    ny_ArenaClock(State.Player2, 10)

    sleep(100)

    ny_ArenaClock(State.Player1, 300)
    ny_ArenaClock(State.Player2, 300)
    while State.InCombat do
        Sleep(10)  -- 1 Second

        State.FightTime  = State.FightTime + 1
        P1Dead = ReadRoleValue(State.Player1, EM_RoleValue_IsDead)
        P2Dead = ReadRoleValue(State.Player2, EM_RoleValue_IsDead)

        if P1Dead == 1 or P2Dead == 1 then 
            State.Winner = (P1Dead == 1) and State.Player2 or State.Player1
            State.Loser  = (State.Winner == State.Player1) and State.Player2 or State.Player1

            ny_Chat(State.Winner, "You win!");  Lua_SysWarning(State.Loser, "You lose.")
            AddMoney(State.Winner, CURRENCY_TYPE, WIN_REWARD,  EM_ActionType_PlotGive)
            AddMoney(State.Loser,  CURRENCY_TYPE, LOSE_REWARD, EM_ActionType_PlotGive)

            ny_ClearPvPBuffs(State.Player1); ny_ClearPvPBuffs(State.Player2)
            ny_Teleport(State.Player1, LOBBY_POS); ny_Teleport(State.Player2, LOBBY_POS)

            ny_LogTracking()

            for Player, Info in pairs(SavedFaction) do
                WriteRoleValue(Player, EM_RoleValue_GuildID, Info.Guild)
                WriteRoleValue(Player, EM_RoleValue_UnionID, Info.Union)
            end
            DelObj(State.Placeholder)

            ClockClose(State.Player1, 0 )
            ClockClose(State.Player2, 0 )
            State.FightTime   = 0
            State.Placeholder = nil
            State.Player1     = nil
            State.Player2     = nil
            State.InCombat    = false
        elseif State.FightTime >= 300 then                   -- Five‑minute timeout
            ny_Chat(State.Player1, "Time limit reached - draw.")
            ny_Chat(State.Player2, "Time limit reached - draw.")
            ClockClose(State.Player1, 0 )
            ClockClose(State.Player2, 0 )
            ny_ClearPvPBuffs(State.Player1); ny_ClearPvPBuffs(State.Player2)
            ny_Teleport(State.Player1, LOBBY_POS); ny_Teleport(State.Player2, LOBBY_POS)

            for Player, Info in pairs(SavedFaction) do
                WriteRoleValue(Player, EM_RoleValue_GuildID, Info.Guild)
                WriteRoleValue(Player, EM_RoleValue_UnionID, Info.Union)
            end
            DelObj(State.Placeholder)

            State.FightTime   = 0
            State.Placeholder = nil
            State.Player1     = nil
            State.Player2     = nil
            State.InCombat    = false
        end
    end
end

-- 3. Player chooses to leave the queue
function ny_QuitQueue()
    local Me = OwnerID()
    DialogCreate(Me, EM_LuaDialogType_YesNo, "Do you wish to leave the queue?")
    DialogSendOpen(Me)

    for _ = 1, 20 do
        local Result = DialogGetResult(Me)
        if Result == 0 then DialogClose(Me); return            -- No
        elseif Result == 1 then                                -- Yes
            DialogClose(Me); ny_RemoveFromQueue(Me); ny_Chat(Me, "You left the queue!"); return
        end
        Sleep(10)
    end
end

-- 4. Spectator teleports
function ny_PvP_Spectate()
    local Player = OwnerID(); ny_Teleport(Player, SPECTATE_POS); 
    if CountBodyItem(Player, SPECTATOR_ITEM) == 0 then GiveBodyItem(Player, SPECTATOR_ITEM, 1) end

    ny_Chat(Player, "You are now Spectating. To leave, use the item given to you")
    for _, Buff in ipairs(SPECTATOR_BUFFS) do
        AddBuff(Player, Player, Buff, 1000, 9999999)
    end
end

function ny_PvP_Spectate_Leave()
    local Player = OwnerID()
    if State.InCombat and (Player == State.Player1 or Player == State.Player2) then
        ny_Chat(Player, "You can't leave the arena while your fight is still running!")
        return
    end
    ny_ClearPvPBuffs(Player)
    ny_Teleport(Player, LOBBY_POS)
end

function ny_Logout()
    local Player = OwnerID()
    if State.InCombat and (Player == State.Player1 or Player == State.Player2) then
        State.FightTime = 9999999
    end

    ny_RemoveFromQueue(Player)
end

function ny_PvP_Teleport()
    ChangeWorld(OwnerID(), 2, 104, 0, 12, 1150, 548, 0)
end

function qaz_1205_20012322Egg()--赤色彗星轉蛋_sin要的
	local World = ReadRoleValue(OwnerID(), EM_RoleValue_WorldID)
	local Zone = ReadRoleValue(OwnerID(), EM_RoleValue_ZoneID)
	if (Zone == 104 or Zone == 313) and World == 2 then
		ny_PvP_Spectate_Leave()
	end
end
