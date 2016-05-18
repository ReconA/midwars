local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = true
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'


-----------------------------------
--Constants
-----------------------------------

behaviorLib.StartingItems  = { "Item_RunesOfTheBlight", "Item_MinorTotem", "Item_MinorTotem", "Item_MarkOfTheNovice", "Item_MarkOfTheNovice", "Item_HealthPotion"}
behaviorLib.LaneItems  = {"Item_Marchers"}

-- Aggression up from
object.nHoldUp = 10;
object.nShowUp = 20;
object.nFullWhip = 10;
object.nVoodooUp = 40;


-- Skillbuild table, 0=Hold, 1=Puppet Show, 2=Whiplash, 3=Voodoo, 4=Attri
object.tSkills = {
  2, 0, 2, 2, 2,
  3, 1, 3, 1, 1,
  3, 4, 4, 4, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 1, Mid = 5, ShortSolo = 4, LongSolo = 1, ShortSupport = 1, LongSupport = 1, ShortCarry = 4, LongCarry = 3}

----------------------------------
--  FindItems Override
----------------------------------
--local function funcFindItemsOverride(botBrain)
--    local bUpdated = object.FindItemsOld(botBrain)
--
--    if core.itemSheepstick ~= nil and not core.itemSheepstick:IsValid() then
--        core.itemSheepstick = nil
--    end
--
--    if bUpdated then
--        --only update if we need to
--        if core.itemSheepstick then
--            return
--        end
--
--        local inventory = core.unitSelf:GetInventory(true)
--        for slot = 1, 12, 1 do
--            local curItem = inventory[slot]
--            if curItem then
--                if core.itemSheepstick == nil and curItem:GetName() == "Item_Morph" then
--                    core.itemSheepstick = core.WrapInTable(curItem)
--                end
--            end
--        end
--    end
--end
--object.FindItemsOld = core.FindItems
--core.FindItems = funcFindItemsOverride

--------------------------------
-- Skills
--------------------------------
function object:SkillBuild()
  core.VerboseLog("SkillBuild()")

  -- takes care at load/reload, <NAME_#> to be replaced by some convinient name.
  local unitSelf = self.core.unitSelf
  if  skills.hold == nil then
    skills.hold = unitSelf:GetAbility(0)
    skills.show = unitSelf:GetAbility(1)
    skills.whip = unitSelf:GetAbility(2)
    skills.voodoo = unitSelf:GetAbility(3)
    skills.abilAttr = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local nLev = unitSelf:GetLevel()
  local nLevPts = unitSelf:GetAbilityPointsAvailable()
  for i = nLev, nLev+nLevPts do
    unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
  end
end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end

-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

-- people can/well override this function to heal at well better (bottle sip etc) called the whole time
function behaviorLib.CustomHealAtWellExecute(botBrain)
  return false
end

-- Hold an nearby enemy hero while retreating
function behaviorLib.CustomRetreatExecute(botBrain)

  local abilHold = skills.hold
  local nRange = abilHold:GetRange()

  local unitSelf = core.unitSelf
  local vecMyPosition = unitSelf:GetPosition()

  if abilHold and abilHold:CanActivate() then
    core.BotEcho("HOLD?")

    local tTargets = core.localUnits["EnemyHeroes"]
    for key, hero in pairs(tTargets) do
      local heroPos = hero:GetPosition()
      local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, heroPos)
      if nTargetDistanceSq < (nRange * nRange / 2) then
        BotEcho("HOLDING!")
        return core.OrderAbilityEntity(botBrain, abilHold, hero)
      end

    end

  end

  return false
end


------------------------------------------------------
--            CustomHarassUtility Override          --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  if skills.whip:GetCharges() == 1 then
    nUtil = nUtil + object.nFullWhip
  end

  if skills.voodoo:CanActivate() then
    nUtil = nUtil + object.nVoodooUp
  end

  if skills.hold:CanActivate() then
    nUtil = nUtil + object.nHoldUp
  end

  return nUtil
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

------------------------
--Location functions
-----------------------
--local function isEnemyNearPuppet(enemy) 
--  local vEnemyPos = enemy:GetPosition()
--end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return object.harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  local nLastHarassUtility = behaviorLib.lastHarassUtil
  local bCanSee = core.CanSeeUnit(botBrain, unitTarget)
  local bActionTaken = false

  local myPos = unitSelf: GetPosition()
  local nRadius = 600
  local tEnemies = core.AssessLocalUnits(botBrain, myPos, nRadius).Enemies

  for _, enemy in pairs(tEnemies) do --If a puppet exists, set it as the target
    if enemy:GetTypeName() == "Pet_PuppetMaster_Ability4" then
      unitTarget = enemy
      BotEcho("TARGETING PUPPET")
    end
  end
  
  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilShow = skills.show
    
    if abilShow:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, unitTarget)
    end

  end

  if not bActionTaken and bCanSee then
    local abilVoodoo = skills.voodoo

    if abilVoodoo:CanActivate() then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilVoodoo, unitTarget)
    end

  end

    if not bActionTaken then
        return object.harassExecuteOld(botBrain)
    end
end

-- overload the behaviour stock function with n
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading puppetmaster_main')
