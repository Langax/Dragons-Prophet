--==============================================================
--  Spider Lair Dungeon
--  Current Version: 2.3.1
--  Author: Lang
--==============================================================

-- ─── Constants ──────────────────────────────────────────────
local NPC_PLACEHOLDER_ID    = 10010269
local NPC_PLACEHOLDER_FLAG  = 45002000

local NPC_DOOR_ID           = 10012309
local NPC_BIG_DOOR_ID       = 10012537
local NPC_DOOR_FLAG         = 45001800

local BOSS_BUFF_ON_COMBAT   = 30015580

local ANTI_CHEATING_BUFF    = 30007109
-- ─── Path One ───────────────────────────────────────────────
local FLAG_PATH_ONE_NPC     = { 45001900, 45001901, 45001902, 45001903 }  -- Normal Spider, Stunning Spider, Elite Spider, Small Spider
local NPC_SPIDER_ID         = { 10004776, 10006736, 10011463, 10007466 }  -- Normal Spider, Stunning Spider, Elite Spider, Small Spider

local PATH_ONE_KILL_GOAL    = 35

local FLAG_BOSS_ONE         = 45002001
local NPC_BOSS_ONE          = 11000185
local BOSS_ONE_AI           = "ny_CrawlerBossAI"

-- ─── Path Two ───────────────────────────────────────────────
local FLAG_PATH_TWO_NPC     = { 45001904, 45001905, 45001906, 45001907 }  -- Normal Bandit, Healer Goblin, Elite Bandit, Stunning Goblin
local NPC_BANDIT_ID         = { 10015937, 10007469, 10006703, 10006862 }  -- Normal Bandit, Healer Goblin, Elite Bandit, Stunning Goblin

local PATH_TWO_KILL_GOAL    = 80

local FLAG_BOSS_TWO         = 45002002
local NPC_BOSS_TWO          = 10006324
local BOSS_TWO_BUFF         = 30015458
local BOSS_TWO_SPIDERS      = 10005812
local BOSS_TWO_CRYSTAL      = 10003755
local BOSS_TWO_AI           = "ny_SpawnerBossAI"

-- ─── Script‑wide state ──────────────────────────────────────
local State = {
    RoomID        = 0,
    Placeholder   = nil,
    Doors         = {},
    Packs         = {},
    Boss          = nil,
    RangeAnchor   = nil,  -- invisible radius checker
    EntranceDoor  = nil,

    KillCount     = 0,
    InCombat      = false,
    QuestDone     = false,

    BossOneDead   = false,
    BossTwoDead   = false,

    SpiderCount   = 0,
    Spiders       = {},
    Crystal       = {}
}

-- ─── Utility helpers ────────────────────────────────────────
local function ny_Debug(msg) DebugMsg(0, "[Nyhil Debug] "..msg) end

local function ny_SetStaticDoor(door)
    SetModeEx(door, EM_SetModeType_Mark,         false)
    SetModeEx(door, EM_SetModeType_Strikback,    false)
    SetModeEx(door, EM_SetModeType_Move,         false)
    SetModeEx(door, EM_SetModeType_Fight,        false)
    SetModeEx(door, EM_SetModeType_Searchenemy,  false)
    SetModeEx(door, EM_SetModeType_ShowMinimap,  false)
    SetModeEx(door, EM_SetModeType_Obstruct,     true)
    SetModeEx(door, EM_SetModeType_ShowName,     false)
    SetModeEx(door, EM_SetModeType_Show,         true)
end

local function ny_SetAggressiveMob(mob)
    SetModeEx(mob, EM_SetModeType_Mark,         true)
    SetModeEx(mob, EM_SetModeType_Move,         true)
    SetModeEx(mob, EM_SetModeType_Fight,        true)
    SetModeEx(mob, EM_SetModeType_Searchenemy,  true)
    SetModeEx(mob, EM_SetModeType_Show,         true)
end

local function ny_SpawnDoor(flag, idx)
    local door = CreateObjByFlag(NPC_BIG_DOOR_ID, flag, idx)
    ny_SetStaticDoor(door)
    AddToPartition(door, State.RoomID)
    return door
end

local function ny_SpawnPack(count, npcId, flagBase)
    for i = 0, count - 1 do
        local mob = CreateObjByFlag(npcId, flagBase, i)
        ny_SetAggressiveMob(mob)
        WriteRoleValue(mob, EM_RoleValue_Lv, (ReadRoleValue(OwnerID(), EM_RoleValue_PlayerMaxLv))+5)
        AddToPartition(mob, State.RoomID)
        table.insert(State.Packs, mob)
    end
end

local function ny_CreatePlaceholder()
    local ph = CreateObjByFlag(NPC_PLACEHOLDER_ID, NPC_PLACEHOLDER_FLAG, 0)
    SetModeEx(ph, EM_SetModeType_Show, false)
    AddToPartition(ph, State.RoomID)
    return ph
end

local function ny_ScriptMessage(Message)
	ScriptMessage( OwnerID() , OwnerID() , EM_ScriptMessageSendType_Room , EM_ClientMessage_Chat , Message , 0 ) 
	ScriptMessage( OwnerID() , OwnerID() , EM_ScriptMessageSendType_Room , EM_ClientMessage_Quest , Message , 0 ) 
end

-- ─── Public Entry Point ─────────────────────────────────────
function ny_SpiderQuest(Version, collisionBoxID)
    State.RoomID      = ReadRoleValue(OwnerID(), EM_RoleValue_RoomID)
    State.Placeholder = ny_CreatePlaceholder()

    DisableCollisionBox(collisionBoxID, State.RoomID, 1)

    if Version == 1 then
        BeginPlot(State.Placeholder, "ny_SpiderPathOne", 0)
        BeginPlot(State.Placeholder, "ny_CrawlerBoss"  , 0)
    elseif Version == 2 then
        BeginPlot(State.Placeholder, "ny_SpiderPathTwo", 0)
        BeginPlot(State.Placeholder, "ny_SpawnerBoss",  0)        
    else
        ny_Debug("Future quest version ("..Version..") not implemented.")
    end
end






--██████╗░░█████╗░████████╗██╗░░██╗   █████╗░███╗░░██╗███████╗
--██╔══██╗██╔══██╗╚══██╔══╝██║░░██║   ██╔══██╗████╗░██║██╔════╝
--██████╔╝███████║░░░██║░░░███████║   ██║░░██║██╔██╗██║█████╗░░
--██╔═══╝░██╔══██║░░░██║░░░██╔══██║   ██║░░██║██║╚████║██╔══╝░░
--██║░░░░░██║░░██║░░░██║░░░██║░░██║   ╚█████╔╝██║░╚███║███████╗
--╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝   ░╚════╝░╚═╝░░╚══╝╚══════╝


function ny_SpiderPathOne()
    -- door that opens once enough spiders are dead
    local doorPath = ny_SpawnDoor(NPC_DOOR_FLAG, 0)

    ny_ScriptMessage("Strike down 35 Spiders to break through!")

    -- spawn spider waves
    ny_SpawnPack(11, NPC_SPIDER_ID[1], FLAG_PATH_ONE_NPC[1])
    ny_SpawnPack(7,  NPC_SPIDER_ID[2], FLAG_PATH_ONE_NPC[2])
    ny_SpawnPack(5,  NPC_SPIDER_ID[3], FLAG_PATH_ONE_NPC[3])
    ny_SpawnPack(20, NPC_SPIDER_ID[4], FLAG_PATH_ONE_NPC[4])

    for i = #State.Packs, 1, -1 do
        local mob = State.Packs[i]
        PlayMotionEX(mob, 34000240, 34000240, ReadRoleValue(mob, EM_RoleValue_PID) )
    end

    while true do
        Sleep(10)
        for i = #State.Packs, 1, -1 do
            local mob = State.Packs[i]
            if ReadRoleValue(mob, EM_RoleValue_IsDead) == 1 then
                State.KillCount = State.KillCount + 1
                DelObj(mob)
                table.remove(State.Packs, i)
                ny_Debug("Kills: "..State.KillCount.."/"..PATH_ONE_KILL_GOAL)
            end
        end

        if State.KillCount >= PATH_ONE_KILL_GOAL then
            DelObj(doorPath)
            ny_Debug("Path One cleared!")
            ny_ScriptMessage("The path ahead opens!")
            State.KillCount = 0
            State.QuestDone = true
            -- clean leftovers (if any)
            for _, m in ipairs(State.Packs) do DelObj(m) end
            State.Packs = {}
            break
        end
    end
end

-- ─── Boss Encounter supervisor ──────────────────────────────
function ny_CrawlerBoss()
    -- boss stub
    local boss = CreateObjByFlag(NPC_BOSS_ONE, FLAG_BOSS_ONE, 1)
    State.InCombat = false
    ny_SetAggressiveMob(boss)
    SetModeEx(boss, EM_SetModeType_Fight, false)       -- inactive until pulled
    SetModeEx(boss, EM_SetModeType_Searchenemy, false)
    AddToPartition(boss, State.RoomID)
    WriteRoleValue(boss, EM_RoleValue_Register, 0)     -- combat flag

    BeginPlot(boss, BOSS_ONE_AI, 20)
    State.Boss = boss

    -- static door behind boss room
    local exitDoor = ny_SpawnDoor(NPC_DOOR_FLAG, 1)

    -- invisible radius checker
    State.RangeAnchor = CreateObjByFlag(NPC_PLACEHOLDER_ID, NPC_PLACEHOLDER_FLAG, 1)
    SetModeEx(State.RangeAnchor, EM_SetModeType_Show, false)
    AddToPartition(State.RangeAnchor, State.RoomID)

    ----------------------------------------------------------------
    -- main loop
    ----------------------------------------------------------------

    while true do
        Sleep(5)
        local flag = ReadRoleValue(boss, EM_RoleValue_Register)

        -- players entered range: wake boss & seal entrance
        if not State.InCombat then
            local players = Dinaya_SearchPlayerArray(State.RangeAnchor, 50)
            if players ~= 0 then
                ny_Debug("Boss engaged")
                Lua_MK_SetPosByFlag(boss, FLAG_BOSS_ONE, 0)
                Castspell(boss,boss,31002120,0);
                SetModeEx(boss, EM_SetModeType_Fight, true)
                SetModeEx(boss, EM_SetModeType_Searchenemy, true)
                AddBuff(boss, boss, BOSS_BUFF_ON_COMBAT, 1, 9999999)
                State.EntranceDoor = ny_SpawnDoor(NPC_DOOR_FLAG, 0)
                State.InCombat = true
            end
        end

        -- combat reset
        if flag == 2 then
            ny_Debug("Boss reset")
            if State.EntranceDoor then DelObj(State.EntranceDoor) end
            DelObj(State.RangeAnchor)
            DelObj(boss)

            boss = CreateObjByFlag(NPC_BOSS_ONE, FLAG_BOSS_ONE, 1)
            ny_SetAggressiveMob(boss)
            SetModeEx(boss, EM_SetModeType_Fight, false)
            SetModeEx(boss, EM_SetModeType_Searchenemy, false)
            AddToPartition(boss, State.RoomID)
            WriteRoleValue(boss, EM_RoleValue_Register, 0)
            BeginPlot(boss, BOSS_ONE_AI, 20)

            State.RangeAnchor = CreateObjByFlag(NPC_PLACEHOLDER_ID, FLAG_BOSS_ONE, 0)
            SetModeEx(State.RangeAnchor, EM_SetModeType_Show, false)
            AddToPartition(State.RangeAnchor, State.RoomID)

            State.InCombat     = false
            State.EntranceDoor = nil
        end

        -- boss dead
        if flag == 3 or ReadRoleValue(boss, EM_RoleValue_IsDead) == 1 then
            ny_Debug("Boss defeated")
            if State.EntranceDoor then DelObj(State.EntranceDoor) end
            if State.QuestDone == false then State.BossOneDead = false; else State.BossOneDead = true end
            State.QuestDone   = false
            DelObj(exitDoor)      -- open next section
            DelObj(State.RangeAnchor)
            DelObj(boss)
            State.InCombat = false
            break
        end

        if State.QuestDone == false then
            AddBuff(boss, boss, ANTI_CHEATING_BUFF, 1, 99999999)
        else
            CancelBuff(boss, ANTI_CHEATING_BUFF)
        end
    end
end

-- ─── Boss AI (minimal placeholder) ──────────────────────────
function ny_CrawlerBossAI()
    local boss     = OwnerID()
    local inCombat = false

    while true do
        Sleep(20)
        if HateListCount(boss) > 0 then
            if not inCombat then
                WriteRoleValue(boss, EM_RoleValue_Register, 1) -- fighting
                inCombat = true
            end
        else
            if inCombat then
                WriteRoleValue(boss, EM_RoleValue_Register, 2) -- leash
                inCombat = false
            end
        end
    end
end






--██████╗░░█████╗░████████╗██╗░░██╗   ████████╗░██╗░░░░░░░██╗░█████╗░
--██╔══██╗██╔══██╗╚══██╔══╝██║░░██║   ╚══██╔══╝░██║░░██╗░░██║██╔══██╗
--██████╔╝███████║░░░██║░░░███████║   ░░░██║░░░░╚██╗████╗██╔╝██║░░██║
--██╔═══╝░██╔══██║░░░██║░░░██╔══██║   ░░░██║░░░░░████╔═████║░██║░░██║
--██║░░░░░██║░░██║░░░██║░░░██║░░██║   ░░░██║░░░░░╚██╔╝░╚██╔╝░╚█████╔╝
--╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝   ░░░╚═╝░░░░░░╚═╝░░░╚═╝░░░╚════╝░


function ny_SpiderPathTwo()
    -- door that opens once enough bandits are dead
    local doorPath = ny_SpawnDoor(NPC_DOOR_FLAG, 2)

    ny_ScriptMessage("Bandits block the way! Kill 80 to pass through!")
    -- spawn bandit waves
    ny_SpawnPack(47, NPC_BANDIT_ID[1], FLAG_PATH_TWO_NPC[1])
    ny_SpawnPack(18,  NPC_BANDIT_ID[2], FLAG_PATH_TWO_NPC[2])
    ny_SpawnPack(10,  NPC_BANDIT_ID[3], FLAG_PATH_TWO_NPC[3])
    ny_SpawnPack(22, NPC_BANDIT_ID[4], FLAG_PATH_TWO_NPC[4])

    while true do
        Sleep(10)
        for i = #State.Packs, 1, -1 do
            local mob = State.Packs[i]
            if ReadRoleValue(mob, EM_RoleValue_IsDead) == 1 then
                State.KillCount = State.KillCount + 1
                DelObj(mob)
                table.remove(State.Packs, i)
                ny_Debug("Kills: "..State.KillCount.."/"..PATH_TWO_KILL_GOAL)
            end
        end

        if State.KillCount >= PATH_TWO_KILL_GOAL then
            DelObj(doorPath)
            ny_Debug("Path Two cleared!")
            ny_ScriptMessage("The path ahead opens!")
            state.QuestDone = true
            -- clean leftovers (if any)
            for _, m in ipairs(State.Packs) do DelObj(m) end
            State.Packs = {}
            break
        end
    end
end

-- ─── Boss Encounter supervisor ──────────────────────────────
function ny_SpawnerBoss()
    local boss = CreateObjByFlag(NPC_BOSS_TWO, FLAG_BOSS_TWO, 0)
    State.InComat = false
    ny_SetAggressiveMob(boss)
    SetModeEx(boss, EM_SetModeType_Fight,       false)       -- inactive until pulled
    SetModeEx(boss, EM_SetModeType_Obstruct,    true)
    SetModeEx(boss, EM_SetModeType_Move,        false)
    AddToPartition(boss, State.RoomID)
    WriteRoleValue(boss, EM_RoleValue_Register+1, 0)     -- combat flag
    WriteRoleValue(boss, EM_RoleValue_Lv, (ReadRoleValue(OwnerID(), EM_RoleValue_PlayerMaxLv)+5))
    WriteRoleValue(boss, EM_RoleValue_VIT, 100000)

    BeginPlot(boss, BOSS_TWO_AI, 20)
    State.Boss = boss

    -- static door behind boss room
    local exitDoor = ny_SpawnDoor(NPC_DOOR_FLAG, 3)

    -- invisible radius checker
    State.RangeAnchor = CreateObjByFlag(NPC_PLACEHOLDER_ID, NPC_PLACEHOLDER_FLAG, 2)
    SetModeEx(State.RangeAnchor, EM_SetModeType_Show, false)
    AddToPartition(State.RangeAnchor, State.RoomID)

    ----------------------------------------------------------------
    -- main loop
    ----------------------------------------------------------------

    while true do
        Sleep(10)
        local flag = ReadRoleValue(boss, EM_RoleValue_Register+1)

        -- players entered range: wake boss & seal entrance
        if not State.InCombat then
            local players = Dinaya_SearchPlayerArray(State.RangeAnchor, 200)
            if players ~= 0 then
                ny_Debug("Boss engaged")
                SetModeEx(boss, EM_SetModeType_Fight,       true)
                AddBuff(boss, boss, BOSS_BUFF_ON_COMBAT, 1  , 9999999)
                AddBuff(boss, boss, BOSS_TWO_BUFF      , 1  , 9999999)

                for i, player in pairs(players) do
                    ny_Debug("Setting boss head bar!")
                    Lua_SetBossHeadBar(player, boss)
                end

                State.EntranceDoor = ny_SpawnDoor(NPC_DOOR_FLAG, 4)
                State.InCombat = true
            end
        end

        if flag == 1 then
            if #State.Spiders >= 1 then
                for i = 1, #State.Spiders do
                    if ReadRoleValue(State.Spiders[i], EM_RoleValue_IsDead) == 1 then
                        DelObj(State.Spiders[i])
                        table.remove(State.Spiders, i)
                    end
                end
            end

            if #State.Spiders >= 10 then
                for i = 1, #State.Spiders do
                    AddBuff(State.Spiders[i], State.Spiders[i], 30015470, 1, 1000000)
                end
            end

            if #State.Crystal >= 1 then
                if ReadRoleValue(State.Crystal[1], EM_RoleValue_IsDead) == 1 then
                    ny_Debug("First crystal down!")
                    sleep(20) -- 2 Second window to kill the other crystal(s)
                    if ReadRoleValue(State.Crystal[2], EM_RoleValue_IsDead) == 1 then
                        ny_Debug("Both crystals dead!")
                        local CurrentHP = ReadRoleValue(boss, EM_RoleValue_HP)
                        local NewHP     = CurrentHP * 0.8
                        WriteRoleValue(boss, EM_RoleValue_HP, NewHP)
                        delobj(State.Crystal[1])
                        delobj(State.Crystal[2])
                        table.remove(State.Crystal, 1)
                        table.remove(State.Crystal, 1)
                    else
                        ny_Debug("Failed to kill the second crystal in time")
                        delobj(State.Crystal[1])
                        delobj(State.Crystal[2])
                        table.remove(State.Crystal, 1)
                        table.remove(State.Crystal, 1)
                    end
                elseif ReadRoleValue(State.Crystal[2], EM_RoleValue_IsDead) == 1 then
                    ny_Debug("First crystal down!")
                    sleep(20)
                    if ReadRoleValue(State.Crystal[1], EM_RoleValue_IsDead) == 1 then
                        ny_Debug("Both crystals dead!")
                        local CurrentHP = ReadRoleValue(boss, EM_RoleValue_HP)
                        local NewHP     = CurrentHP * 0.8
                        WriteRoleValue(boss, EM_RoleValue_HP, NewHP)
                        delobj(State.Crystal[1])
                        delobj(State.Crystal[2])
                        table.remove(State.Crystal, 1)
                        table.remove(State.Crystal, 1)
                    else
                        ny_Debug("Failed to kill the second crystal in time")
                        delobj(State.Crystal[1])
                        delobj(State.Crystal[2])
                        table.remove(State.Crystal, 1)
                        table.remove(State.Crystal, 1)
                    end
                end
            end
        end

        -- combat reset
        if flag == 2 then
            ny_Debug("Boss reset")
            if State.EntranceDoor then DelObj(State.EntranceDoor) end
            DelObj(State.RangeAnchor)
            DelObj(boss)

            boss = CreateObjByFlag(NPC_BOSS_TWO, FLAG_BOSS_TWO, 0)
            ny_SetAggressiveMob(boss)
            SetModeEx(boss, EM_SetModeType_Fight, false)
            SetModeEx(boss, EM_SetModeType_Searchenemy, false)
            AddToPartition(boss, State.RoomID)
            WriteRoleValue(boss, EM_RoleValue_Register+1, 0)
            BeginPlot(boss, BOSS_TWO_AI, 20)

            State.RangeAnchor = CreateObjByFlag(NPC_PLACEHOLDER_ID, NPC_PLACEHOLDER_FLAG, 2)
            SetModeEx(State.RangeAnchor, EM_SetModeType_Show, false)
            AddToPartition(State.RangeAnchor, State.RoomID)

            State.InCombat     = false
            State.EntranceDoor = nil
        end

        -- boss dead
        if flag == 3 or ReadRoleValue(boss, EM_RoleValue_IsDead) == 1 then
            ny_Debug("Boss defeated")
            if State.EntranceDoor then DelObj(State.EntranceDoor) end
            if State.QuestDone == false then State.BossTwoDead = false; else State.BossTwoDead = true end
            State.QuestDone   = false
            DelObj(exitDoor)      -- open next section
            DelObj(State.RangeAnchor)
            DelObj(boss)
            break
        end

        if State.QuestDone == false or State.BossOneDead == false then
            AddBuff(boss, boss, ANTI_CHEATING_BUFF, 1, 99999999)
        else
            CancelBuff(boss, ANTI_CHEATING_BUFF)
        end
    end
end

-- ─── Boss AI ───────────────────────────────────────────────
function ny_SpawnerBossAI()
    local boss     = OwnerID()
    local inCombat = false
    local Skill_1, Skill_2, Skill_3 = 0, 0, 0

    while true do
        Sleep(10)
        local players = Dinaya_SearchPlayerArray(State.RangeAnchor, 500)
        if players ~= 0 then
            if not inCombat then
                inCombat = true
                WriteRoleValue(boss, EM_RoleValue_Register+1, 1)
            else
                Skill_1, Skill_2, Skill_3 = Skill_1 +1 , Skill_2 + 1, Skill_3 + 1
                if Skill_3 >= 80 then
                    BeginPlot(boss, "ny_SpawnerBoss_Crystals", 0)
                    Skill_3 = 0
                    ny_Debug("Skill 3 GO!")
                elseif Skill_2 >= 30 then
                    BeginPlot(boss, "ny_SpawnerBoss_Spiders" , 0)
                    Skill_2 = 0
                    ny_Debug("Skill 2 GO!")
                elseif Skill_1 >= 10 then
                    Sys_CastSpell(boss, boss, 31000402, 0)
                    Skill_1 = 0
                    ny_Debug("Skill 1 GO!")
                end
            end
        else
            if inCombat then
                WriteRoleValue(boss, EM_RoleValue_Register+1, 2)
                inCombat = false
            end
        end
    end
end

function ny_SpawnerBoss_Crystals()
    local boss = OwnerID()
    local playercount = Dinaya_SearchPlayerArray(State.RangeAnchor, 500)
    local crystalcount = 2

    for i = 1, crystalcount do
        local crystal = CreateObjByFlag(BOSS_TWO_CRYSTAL, FLAG_BOSS_TWO, i + 5)
        ny_SetAggressiveMob(crystal)
        AddToPartition(crystal, State.RoomID)
        State.Crystal[#State.Crystal + 1] = crystal
    end
end

function ny_SpawnerBoss_Spiders()
    for i = 0, 3 do
        local spider = CreateObjByFlag(BOSS_TWO_SPIDERS, FLAG_BOSS_TWO, 1)
        ny_SetAggressiveMob(spider)
        AddToPartition(Spider, State.RoomID)
        Lua_MoveToFlag(spider, 45002002, i+2)
        MoveToFlagEnabled(spider, true)
        sleep(10)
        MoveToFlagEnabled(spider, false)
        State.Spiders[#State.Spiders + 1] = spider
        ny_Debug("Spider Count: "..#State.Spiders)
    end
end
