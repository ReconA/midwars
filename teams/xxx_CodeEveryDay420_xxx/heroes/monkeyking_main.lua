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

BotEcho('loading monkeyking_main...')

object.heroName = 'Hero_MonkeyKing'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}


--------------------------------
--Constants
--------------------------------

-- Skillbuild table, 0=Q, 1=W, 2=E, 3=R, 4=Attri
object.tSkills = {
  1, 0, 1, 2, 1,
  2, 1, 2, 2, 3,
  3, 0, 0, 0, 3,
  4, 3, 4, 4, 4,
  4, 4, 4, 4, 4,
}

behaviorLib.StartingItems = {"Item_LoggersHatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems     = {"Item_Bottle", "Item_EnhancedMarchers"}
behaviorLib.MidItems      = {"Item_SolsBulwark", "Item_Stealth"}
behaviorLib.LateItems     = {"Item_Pierce", "Item_Immunity", "Item_Sasuke", "Item_DaemonicBreastplate", "Item_Silence"}

--------------------------------
--Combo variables
--------------------------------
object.nComboCounter = 0  -- What stage of the combo we are in
object.nComboReady  = 70  -- How much utility from a ready combo
object.nMidCombo    = 80  -- How much utility from being mid combo
object.nComboDuration = 7000 --Combo counter will reset after this time (milliseconds)

--------------------------------
-- Skills
--------------------------------

function object:SkillBuild()
  core.VerboseLog("SkillBuild()")

  local unitSelf = self.core.unitSelf
  if skills.dash == nil then
    skills.dash     = unitSelf:GetAbility(0)
    skills.vault    = unitSelf:GetAbility(1)
    skills.slam     = unitSelf:GetAbility(2)
    skills.nimbus   = unitSelf:GetAbility(3)
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

-----------------------------------------------------
--Local functions
-----------------------------------------------------


local function getDistance2DSq(unit1, unit2)
  if not unit1 or not unit2 then
    BotEcho("INVALID DISTANCE CALC TARGET")
    return 999999
  end
  
  local vUnit1Pos = unit1:GetPosition()
  local vUnit2Pos = unit2:GetPosition()
  return Vector3.Distance2DSq(vUnit1Pos, vUnit2Pos)
end


-- Loaned from master depository generics ^_^
function IsFreeLine(pos1, pos2)
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 50 * 50
  for _, ally in pairs(tAllies) do
    if ally then
      local posAlly = ally:GetPosition()
      if posAlly then
        local x3, y3 = posAlly.x, posAlly.y
        local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
        local calc2 = calc * calc
        local actual = calc2 / distanceLine
        if actual < spaceBetween then
          return false
        end
      end
    end
  end
  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x3, y3 = posCreep.x, posCreep.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      return false
    end
  end
  return true
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

------------------------------------------------------
--            CustomHarassUtility Override          --
------------------------------------------------------
-- @param: IunitEntity hero
-- @return: number
local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  local dash, vault, slam = skills.dash, skills.vault, skills.slam
  if dash and vault and slam and dash:CanActivate() and vault:CanActivate() and slam:CanActivate() then
    nUtil = 60
  end

  return nUtil
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


--------------------------------------------------------------
--                    Combo Behavior                       
-- Combo should be Dash - Slam - Vault - Dash - Vault  (Q E W Q W)
--
--------------------------------------------------------------

local function DetermineComboTarget(dash)

  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = dash:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 9999999
  
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and IsFreeLine(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local comboTarget = nil
local comboCounter = 0
local comboStartTime = nil

local function ComboUtility(botBrain)
  local nTime = HoN.GetGameTime()
  if comboStartTime and nTime - comboStartTime > object.nComboDuration then -- Combo started some time ago, so time to stop
    comboStartTime = nil
    comboCounter = 0
    return 0  
  end

  if comboCounter > 0 then
    return object.nMidCombo
  end
  
  local dash, vault, slam = skills.dash, skills.vault, skills.slam
  if dash and vault and slam and dash:CanActivate() and vault:CanActivate() and slam:CanActivate() then
    comboTarget = DetermineComboTarget(dash)
    if comboTarget then
      return object.nComboReady
    end
  end
  
  return 0
end

local function ComboDash(botBrain)
  local dash = skills.dash
  local bContinue = false
  
  if dash and dash:CanActivate() and comboTarget then
    local targetPos = comboTarget:GetPosition()
    local unitSelf = core.unitSelf
    local myPos = unitSelf:GetPosition()
    local nDistanceSqrd = getDistance2DSq(unitSelf, comboTarget)
    local bFreeLine = IsFreeLine(myPos, targetPos)
    local nFacing = core.HeadingDifference(unitSelf, targetPos)
    local nRange = dash:GetRange()

    if nDistanceSqrd < (nRange * nRange) and nFacing < 0.3 then
      BotEcho("DASH!")
      bContinue = core.OrderAbility(botBrain, dash)
      if not comboStartTime then
        comboStartTime = HoN.GetGameTime()
      end
    end
  end
  
  return bContinue
end

local function ComboVault(botBrain) 
  BotEcho("VAULT?")
  
  local vault = skills.vault
  local bContinue = false
  
  if vault and vault:CanActivate() and comboTarget then
    local targetPos = comboTarget:GetPosition()
    local unitSelf = core.unitSelf
    
    local nRange = vault:GetRange()
    local nDistanceSqrd = getDistance2DSq(unitSelf, comboTarget)
    
    if nDistanceSqrd < (nRange * nRange) then
      BotEcho("VAULT!")
      bContinue =  core.OrderAbilityEntity(botBrain, vault, comboTarget)
    end
    
  end
  
  return bContinue
end

local function ComboSlam(botBrain)
  BotEcho("SLAM?")
  local slam = skills.slam
  local bContinue = false
  
  if comboTarget and not comboTarget:IsStunned() and not comboTarget:IsMagicImmune() and slam and slam:CanActivate() then
    local targetPos = comboTarget:GetPosition()
    local unitSelf = core.unitSelf
    local nRadius = slam:GetTargetRadius()
    local nDistanceSqrd = getDistance2DSq(unitSelf, comboTarget)
    local nFacing = core.HeadingDifference(unitSelf, targetPos)
    if nDistanceSqrd < (nRadius*nRadius) and nFacing < 0.3 then
    BotEcho("SLAM!")
      bContinue = core.OrderAbility(botBrain, slam)
    end
  end
  
  return bContinue
end

local function ComboExecute(botBrain)  
  local slam = skills.slam
  
  local bContinue = false
  
  if comboCounter == 0 or comboCounter == 3 then
    bContinue = ComboDash(botBrain)
  elseif comboCounter == 1 then
    bContinue = ComboVault(botBrain)
  elseif comboCounter == 2 or comboCounter == 4 then
    bContinue = ComboSlam(botBrain)
  else   
    --TODO: What to do mid combo if right now skill can't be cast?
  end
  
  if bContinue then
    comboCounter = comboCounter + 1
  end
end


local ComboBehavior = {}
ComboBehavior["Utility"] = ComboUtility
ComboBehavior["Execute"] = ComboExecute
ComboBehavior["Name"]    = "COMBO"
tinsert(behaviorLib.tBehaviors, ComboBehavior)


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
  
  local bCanSee = core.CanSeeUnit(botBrain, unitTarget)
  if not bCanSee then
    return false 
  end

  local unitSelf = core.unitSelf  
  local bActionTaken = false

  local myPos = unitSelf: GetPosition()
  local targetPos =  unitTarget:GetPosition()



  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end

end

-- overload the behaviour stock function with the new
--object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
--behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


--------------------------------
--Melee Push execute fix
--------------------------------

local function PushExecuteFix(botBrain)


  if core.unitSelf:IsChanneling() then 
    return
  end
  
  local unitSelf = core.unitSelf
  local bActionTaken = false

  --Attack creeps if we're in range
  if bActionTaken == false then
    local unitTarget = core.unitEnemyCreepTarget
    if unitTarget then
      local nRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
      if unitSelf:GetAttackType() == "melee" then
        --override melee so they don't stand *just* out of range
        nRange = 250
      end

      if unitSelf:IsAttackReady() and core.IsUnitInRange(unitSelf, unitTarget, nRange) then
        bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget)
      end

    end
  end

  if bActionTaken == false then
    local vecDesiredPos = behaviorLib.PositionSelfLogic(botBrain)
    if vecDesiredPos then
      bActionTaken = behaviorLib.MoveExecute(botBrain, vecDesiredPos)

    end
  end

  if bActionTaken == false then
    return false
  end
end
behaviorLib.PushBehavior["Execute"] = PushExecuteFix



BotEcho('finished loading monkeyking_main')

