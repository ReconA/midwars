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
-- Utility constants
--------------------------------
object.nComboReady  = 60  -- How much utility from a ready combo
object.nMidCombo    = 70  -- How much utility from being mid combo

object.nDashReady   = 15
object.nVaultReady  = 15
object.nSlamReady   = 15

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
    return object.nComboReady - 10
  end
  
  if skills.dash and skills.dash:CanActivate() then
    nUtil = nUtil + object.nDashReady
  end

  if skills.vault and skills.vault:CanActivate() then
    nUtil = nUtil + object.nVaultReady
  end

  if skills.slam and skills.slam:CanActivate() then
    nUtil = nUtil + object.nSlamReady
  end

  return nUtil
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

--------------------------------------------------------------
--                    Combo Behavior                       
-- Combo should be Dash - Slam - Vault - Dash - Vault  (Q E W Q W)
-- and some autoattacks. 
--------------------------------------------------------------

-- Combo variables
local comboTarget = nil
local comboCounter = 0
local autoAttacks = 0   -- We can add a few autoattack mid-combo
local comboStartTime = nil
local comboEndRange = 400 * 400
local comboDuration = 7000 --Combo counter will reset after this time (milliseconds)

local function IsComboReady()
  local bIsReady = false
  --TODO: Mana
  local dash, vault, slam = skills.dash, skills.vault, skills.slam
  if dash and vault and slam and dash:CanActivate() and vault:CanActivate() and slam:CanActivate() then
    bIsReady = true
  end
  
  return bIsReady
end

local function DetermineComboTarget()

  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = 300
  local maxDistanceSq = maxDistance * maxDistance + 300
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 9999999
  
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end



local function ComboUtility(botBrain)
  local nTime = HoN.GetGameTime()
  if comboStartTime and nTime - comboStartTime > comboDuration then -- Combo started some time ago, so time to stop
    comboStartTime = nil
    comboCounter = 0
    return 0  
  end
  
  if comboTarget then 
    local nDistSqrd = getDistance2DSq(core.unitSelf,comboTarget)
    if nDistSqrd > comboEndRange then
       comboStartTime = nil
       comboCounter = 0
      return 0
    end
  end
  
  if comboCounter > 0 or comboTarget then
    return object.nMidCombo
  end
  
  local dash, vault, slam = skills.dash, skills.vault, skills.slam
  if dash and vault and slam and dash:CanActivate() and vault:CanActivate() and slam:CanActivate() then
    comboTarget = DetermineComboTarget()
    if comboTarget then
      return object.nComboReady
    end
  end
  
  return 0
end

local function ComboDash(botBrain)

  BotEcho("DASH?")
  local dash = skills.dash
  local bContinue = false
  
  if dash and dash:CanActivate() and comboTarget then
    local targetPos = comboTarget:GetPosition()
    local unitSelf = core.unitSelf
    local myPos = unitSelf:GetPosition()
    local nDistanceSqrd = Vector3.Distance2DSq(myPos, targetPos)
    local nFacing = core.HeadingDifference(unitSelf, targetPos)
    local nRange = dash:GetRange()

    BotEcho("Facing:" .. nFacing)
    BotEcho("Distance: " .. nDistanceSqrd)
    BotEcho("Dash range: " .. (nRange * nRange))
    if nDistanceSqrd < (nRange * nRange) and nFacing < 0.4 then
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
  
  local vault = skills.vault  
  local bContinue = false
  
  if vault and vault:CanActivate() and comboTarget then
    local unitSelf = core.unitSelf
    
    local nRange = vault:GetRange()
    local nDistanceSqrd = getDistance2DSq(unitSelf, comboTarget)
    
    if nDistanceSqrd < (nRange * nRange) then
      BotEcho("VAULT!")
      bContinue = core.OrderAbilityEntity(botBrain, vault, comboTarget)
    end
    
  end
  
  return bContinue
end

local function ComboSlam(botBrain)
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

-- Autoattack mid-combo
local function ComboAutoAttack(botBrain)
  BotEcho("MID COMBO AUTOATTACK")
  local bAttack = false
  local unitSelf = core.unitSelf
  if comboTarget and core.IsUnitInRange(unitSelf, comboTarget) then
    bAttack = core.OrderAttack(botBrain, unitSelf, comboTarget)
  end
  
  return bAttack
end

-- Move towards combo target
local function ComboMove(botBrain)
  BotEcho("MID COMBO MOVE")
  local unitSelf = core.unitSelf  
  if comboTarget then
    core.OrderMoveToUnit(botBrain, unitSelf, comboTarget)  
  end
end

-- Combo should be Dash - Slam - Vault - Dash - Vault  (Q E W Q W)
local function ComboExecute(botBrain)  
  BotEcho("COMBO EXECUTE")
  comboTarget = DetermineComboTarget()
  
  local bContinue = false
  
  if comboCounter == 0 or comboCounter == 3 then
    bContinue = ComboDash(botBrain)
  elseif comboCounter == 1 then
--    if autoAttacks < 1 then
--      ComboAutoAttack(botBrain)
--      autoAttacks = autoAttacks + 1
--    else
--      bContinue = ComboSlam(botBrain)
--    end
      bContinue = ComboSlam(botBrain)
  elseif comboCounter == 2 or comboCounter == 4 then
    autoAttacks = 0
    bContinue = ComboVault(botBrain)
  end
  
  if bContinue then
    comboCounter = comboCounter + 1
  else   
    local bAttack = ComboAutoAttack(botBrain)
    if not bAttack then
      ComboMove(botBrain)
    end
  end
  
  return bContinue
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
  
  if IsComboReady() then
    bActionTaken = ComboExecute(botBrain)
  end
  
  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end

end

-- overload the behaviour stock function with the new
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride


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

--------------------------------
--Custom Vault Retreat Behavior
--------------------------------

local function VaultTarget(botBrain)
  local vault = skills.vault
  local target = nil
  local distance = 0
  local myPos = core.unitSelf:GetPosition()
  local mainPos = core.allyMainBaseStructure:GetPosition()
  local unitsNearby = core.AssessLocalUnits(botBrain, myPos, vault:GetRange())
  local fromMain = Vector3.Distance2DSq(myPos, mainPos)
    for id, obj in pairs(unitsNearby.Allies) do
    local fromMainObj = Vector3.Distance2DSq(mainPos, obj:GetPosition())
    if(fromMainObj < fromMain and fromMainObj > distance and Vector3.Distance2D(myPos, obj:GetPosition()) > 150) then
      distance = fromMainObj
      target = obj
    end
  end
  return target
end

function behaviorLib.CustomRetreatExecute(botBrain)
  local vault = skills.vault
  local target = VaultTarget(botBrain)
  local bUsedSkill = false
  local unitSelf = core.unitSelf
  local bLowHp = unitSelf:GetHealthPercent() < 0.40
  
  if bLowHp and vault and vault:CanActivate() and target and Vector3.Distance2D(target:GetPosition(), core.allyWell:GetPosition()) > 2000 then
    bUsedSkill = core.OrderAbilityEntity(botBrain, vault, target)
  end
  
  if not bUsedSkill then
    local dash = skills.dash
    local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
    if bLowHp and dash and dash:CanActivate() and angle < 0.5 then
      bUsedSkill = core.OrderAbility(botBrain, dash)
    end
  end
  
  return bUsedSkill
end

function behaviorLib.CustomRetreatExecute(botBrain)
  local leap = skills.leap
  local unitSelf = core.unitSelf
  local unitsNearby = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 500)

  if unitSelf:GetHealthPercent() < 0.3 and core.NumberElements(unitsNearby.EnemyHeroes) > 0 then
    local ulti = skills.ulti
    if ulti and ulti:CanActivate() then
      return core.OrderAbility(botBrain, ulti)
    end
    local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
    if leap and leap:CanActivate() and angle < 0.5 then
      return core.OrderAbility(botBrain, leap)
    end
  end
  return false
end

BotEcho('finished loading monkeyking_main')

