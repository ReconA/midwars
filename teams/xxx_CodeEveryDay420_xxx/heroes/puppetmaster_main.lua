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
behaviorLib.LaneItems  = {"Item_Marchers", "Item_Steamboots", "Item_HelmOfTheVictim"}
behaviorLib.MidItems = {"Item_WhisperingHelm"}


-- Harass up from ready skills
object.nHoldUp   = 10;
object.nFullWhip = 30;
object.nVoodooUp = 70;


-- Skillbuild table, 0=Hold, 1=Puppet Show, 2=Whiplash, 3=Voodoo, 4=Attri
object.tSkills = {
  2, 0, 2, 1, 2,
  3, 2, 3, 0, 3,
  1, 3, 1, 0, 1,
  0, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

--------------------------------
-- Puppet variables
--------------------------------
object.sPuppetName = "Pet_PuppetMaster_Ability4"
object.puppetTarget = nil

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 1, Mid = 5, ShortSolo = 4, LongSolo = 1, ShortSupport = 1, LongSupport = 1, ShortCarry = 4, LongCarry = 3}

------------------------
--Local functions
-----------------------

local function getDistance2DSq(unit1, unit2)
  if not unit1 or not unit2 then
    BotEcho("INVALID DISTANCE CALC TARGET")
    return 999999
  end
  
  local vUnit1Pos = unit1:GetPosition()
  local vUnit2Pos = unit2:GetPosition()
  return Vector3.Distance2DSq(vUnit1Pos, vUnit2Pos)
end

local function getNearestUnit(botBrain, hero, nRadius) 
  local nSmallestDist = 99999;
  local tEnemies = core.AssessLocalUnits(botBrain, vHeroPos, nRadius).Enemies
  local closestUnit = nil
  local unitSelf = core.unitSelf
  
  for _, enemy in pairs(tEnemies) do
    local nTargetDistanceSq = getDistance2DSq(hero, enemy)    
      if nTargetDistanceSq < nSmallestDist and enemy:GetUniqueID() ~= hero:GetUniqueID() and enemy:GetUniqueID() ~= unitSelf:GetUniqueID()  then
        nSmallestDist =  nTargetDistanceSq
        closestUnit = enemy
      end
  end
    
  return closestUnit
  
end

  --Echo unit closest to target hero
--  if closestUnit then
--    BotEcho(closestUnit:GetTypeName())
--  end

-- Echo behavior of the target
local function echoHeroBehavior(unitTarget)
  if unitTarget:IsHero() and unitTarget:GetBehavior() and unitTarget:GetBehavior():GetType() then
    BotEcho("Target behavior is " .. unitTarget:GetBehavior():GetType())  
  end
end

-- Get the voodoo puppet
local function getPuppet(botBrain, myPos)
  local nRadius = 600
  local tEnemies = core.AssessLocalUnits(botBrain, myPos, nRadius).Enemies

  for _, enemy in pairs(tEnemies) do --If a puppet exists, set it as the target
    if enemy:GetTypeName() == "Pet_PuppetMaster_Ability4" then
      BotEcho("FOUND PUPPET")
      return enemy
    end
  end
end

-- Harass behavior when a puppet exists
local function puppetExistsHarass(botBrain, unitTarget, puppet)
  BotEcho("PUPPET HARASS")

  local bActionTaken = false;
  local unitSelf = core.unitSelf
  
  
  -- If the puppet target is far from puppet, cast hold 
  local nDistToPuppet = getDistance2DSq(puppet, object.puppetTarget)
  local nThreshold = 1000

  if nDistToPuppet > (nThreshold * nThreshold) then 
    local abilHold = skills.hold
    if not bActionTaken and abilHold and abilHold:CanActivate() then
      unitTarget = object.puppetTarget
      local nTargetDistanceSq = getDistance2DSq(unitSelf, unitTarget) 
      local nMyRange = unitSelf:GetAttackRange()

      if nTargetDistanceSq > (nMyRange * nMyRange) then
        BotEcho("HOLD ON PUPPET")
        bActionTaken = core.OrderAbilityEntity(botBrain, abilHold, puppet)
      end
      
    end
  end

 -- If the puppet target is near the puppet, cast Puppet Show
  local abilShow = skills.show
  if abilShow and abilShow: CanActivate() then
    local nRadius = 200 + abilShow:GetLevel() * 50
    local nearestToFoe = getNearestUnit(botBrain, unitTarget, nRadius)
    
    if nearestToFoe and nearestToFoe:GetTypeName() == object.sPuppetName then
      BotEcho("PUPPET SHOW ON PUPPET")
      local bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, puppet)
    end
  end
  
  -- If the puppet target is out of attack range, set the puppet as harass target
  local nDistToTarget = getDistance2DSq(unitSelf, unitTarget)
  local nMyRange = unitSelf:GetAttackRange()
  
  if not bActionTaken then
    if nDistToTarget > (nMyRange * nMyRange) then
      behaviorLib.heroTarget = puppet
    end
  end
  
  
  return bActionTaken
end


-- Harass behavior when a puppet doesn't exist
local function noPuppetExistsHarass(botBrain, unitTarget)
  BotEcho("NO PUPPET HARASS")
  object.puppetTarget = nil

  local bActionTaken = false;
  local unitSelf = core.unitSelf
  local nTargetDistanceSq = getDistance2DSq(unitSelf, unitTarget)
  
  -- Get the cooldown on voodoo
  local nVoodooCD = 9999
  local voodoo = skills.voodoo 
  if voodoo then
    nVoodooCD = voodoo:GetActualRemainingCooldownTime()
  end
  
  -- Cast puppet show if the enemy is near some enemy and voodoo is on cooldown
  local abilShow = skills.show
  if abilShow and abilShow:CanActivate() then
    local nCD = abilShow:GetCooldownTime()
    local nRange = abilShow: GetRange()
    local closestToTarget = getNearestUnit(botBrain, unitTarget, 400) --400 == radius of puppet show
    if nCD < nVoodooCD and nTargetDistanceSq < (nRange * nRange) and closestToTarget then
      BotEcho("DANCE FOR ME")
      bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, unitTarget)
    end
  end
  
  -- Cast hold on enemy under 50% health
  if not bActionTaken and unitTarget:GetHealthPercent() < 50 then
    local abilHold = skills.hold
    if abilHold and abilHold:CanActivate() then
    
      local nRange = abilHold:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilHold, unitTarget)
      end
    end
  end
    
  return bActionTaken
end

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

  if EventData.Type == "Ability" then
    if EventData.InflictorName == "Ability_PuppetMaster4" then
       object.puppetTarget = EventData.TargetUnit
    end
  end
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

  local unitSelf = core.unitSelf
  -- Don't cast hold if on high HP
  if unitSelf:GetHealthPercent() > 80 then
    return false
  end


  local abilHold = skills.hold
  local nRange = abilHold:GetRange()

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

  if skills.voodoo:CanActivate() or object.puppetTarget then
    nUtil = nUtil + object.nVoodooUp
  end

  if skills.hold:CanActivate() then
    nUtil = nUtil + object.nHoldUp
  end

  return nUtil
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride



--------------------------------------------------------------
--                    Harass Behavior                       --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return object.harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
  end
  
  object.lastTarget = unitTarget
  
--  echoHeroBehavior(unitTarget)

  local unitSelf = core.unitSelf

  local nLastHarassUtility = behaviorLib.lastHarassUtil
  local bCanSee = core.CanSeeUnit(botBrain, unitTarget)
  local bActionTaken = false

  local myPos = unitSelf: GetPosition()

  -- Cast voodoo is possible
  local abilVoodoo = skills.voodoo
  if abilVoodoo:CanActivate() then
    BotEcho("VOODOO")
    bActionTaken = core.OrderAbilityEntity(botBrain, abilVoodoo, unitTarget)
  end
  
  local puppet = getPuppet(botBrain, unitTarget)
  
  if puppet then
    bActionTaken = puppetExistsHarass(botBrain, unitTarget, puppet)
  else
    bActionTaken = noPuppetExistsHarass(botBrain, unitTarget)
  end


  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end

end

-- overload the behaviour stock function with the new
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading puppetmaster_main')

--  local nRadius = 600
--  local tEnemies = core.AssessLocalUnits(botBrain, myPos, nRadius).Enemies

--  for _, enemy in pairs(tEnemies) do --If a puppet exists, set it as the target
--    if enemy:GetTypeName() == "Pet_PuppetMaster_Ability4" then
--      unitTarget = enemy
--      BotEcho("TARGETING PUPPET")
--    end
--  end
--  
--  if core.CanSeeUnit(botBrain, unitTarget) then
--    local abilShow = skills.show
--    
--    if abilShow:CanActivate() then
--      bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, unitTarget)
--    end
--
--  end


--  if not nearestEnemy then -- If the target is alone, cast voodoo
--    if not bActionTaken and bCanSee then
--      local abilVoodoo = skills.voodoo
--      if abilVoodoo:CanActivate() then
--        BotEcho("TARGET ALONE. VOODOO")
--        bActionTaken = core.OrderAbilityEntity(botBrain, abilVoodoo, unitTarget)
--      end
--    end
--  else if nearestEnemy == "Pet_PuppetMaster_Ability4" then --If the nearest thing near the target is the puppet, cast puppet show
--    if not bActionTaken and bCanSee then
--      local abilShow = skills.show
--      if abilShow:CanActivate() then
--        BotEcho("TARGET NEAR PUPPET. PUPPET SHOW")
--        bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, unitTarget)
--      end
--    end
--  end
