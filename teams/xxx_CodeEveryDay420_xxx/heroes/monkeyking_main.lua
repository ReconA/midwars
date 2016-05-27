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

object.bReportBehavior = false
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
runfile "bots/teams/xxx_CodeEveryDay420_xxx/heroes/generics.lua"


local core, eventsLib, behaviorLib, metadata, skills, generics = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills, object.generics

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

-- Team group utility. Default is 0.35
behaviorLib.nTeamGroupUtilityMul = 0.45

behaviorLib.StartingItems = {"Item_ManaBattery", "Item_IronBuckler", "Item_Shield2"}
behaviorLib.LaneItems     = {"Item_EnhancedMarchers", "Item_PowerSupply"}
behaviorLib.MidItems      = {"Item_SolsBulwark", "Item_Sicarius", "Item_DaemonicBreastplate"}
behaviorLib.LateItems     = {"Item_Searinglight", "Item_Weapon3", "Item_BehemothsHeart", "Item_Dawnbringer", "Item_Evasion"}

--------------------------------
-- Utility constants
--------------------------------
object.nComboReady  = 10  -- How much utility from a ready combo
object.nMidCombo    = 15  -- How much utility from being mid combo


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

--  local dash, vault, slam = skills.dash, skills.vault, skills.slam
--  if dash and vault and slam and dash:CanActivate() and vault:CanActivate() and slam:CanActivate() then
--    return object.nComboReady - 20
--  end
  return nUtil + generics.CustomHarassUtility(hero)
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
local comboRange = 400 * 400
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


-- Choose combo target. Don't choose targets over #comboRange away.
-- Prioritize team target.
local function DetermineComboTarget(botBrain)

  local teamBotBrain = core.teamBotBrain
  local teamTarget = teamBotBrain:GetTeamTarget()

  if teamTarget and core.CanSeeUnit(botBrain, teamTarget) then
    return teamTarget
  end

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
    if nDistSqrd > comboRange then
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
    comboTarget = DetermineComboTarget(botBrain)
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
    local nDistanceSqrd = Vector3.Distance2DSq(myPos, targetPos)
    local nFacing = core.HeadingDifference(unitSelf, targetPos)
    local nRange = dash:GetRange()

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
  local bAttack = false
  local unitSelf = core.unitSelf
  if comboTarget and core.IsUnitInRange(unitSelf, comboTarget) then
    bAttack = core.OrderAttack(botBrain, unitSelf, comboTarget)
  end

  return bAttack
end

-- Move towards combo target
local function ComboMove(botBrain)
  local unitSelf = core.unitSelf
  if comboTarget then
    core.OrderMoveToUnit(botBrain, unitSelf, comboTarget)
  end
end

-- Combo should be Dash - Slam - Vault - Dash - Vault  (Q E W Q W)
local function ComboExecute(botBrain)
  comboTarget = DetermineComboTarget(botBrain)

  local bContinue = false

  if comboCounter == 0 or comboCounter == 3 then
    bContinue = ComboDash(botBrain)
  elseif comboCounter == 1 then
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


--------------------------------------------------------------
--                    Courier Usage                         --
--------------------------------------------------------------

local function ShopUtilityOverride(botBrain)
  --BotEcho('CanAccessStash: '..tostring(core.unitSelf:CanAccessStash()))

  if behaviorLib.nextBuyTime > HoN.GetGameTime() then
  		return 0
  end
  behaviorLib.buyInterval = 10000
  behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

	behaviorLib.finishedBuying = false

  local units = botBrain:GetLocalUnitsSorted()
  local bCourierFound = false
  -- local units2 = HoN.GetUnitsInRadius(core.unitSelf:GetPosition(), 99999, core.UNIT_MASK_UNIT)
  -- core.printTable(units2)
  for key,curUnit in pairs(units.Allies) do
      if curUnit:IsUnitType("Courier") then
        if curUnit.HeroId == core.unitSelf.Id then
          bCourierFound = true
        end
      end
  end

	local utility = 0
	if not bCourierFound then
		if not core.teamBotBrain.bPurchasedThisFrame then
			utility = 99
		end
	end

	if botBrain.bDebugUtility == true and utility ~= 0 then
		BotEcho(format("  ShopUtility: %g", utility))
	end

	return utility
end

behaviorLib.ShopBehavior["Utility"] = ShopUtilityOverride


local function ShopExecuteOverride(botBrain)
	if object.bUseShop == false then
		return
	end

	behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

	--Determine where in the pattern we are (mostly for reloads)
	if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
		behaviorLib.DetermineBuyState(botBrain)
	end

	local unitSelf = core.unitSelf
	local bShuffled = false
	local bGoldReduced = false
	local tInventory = core.unitSelf:GetInventory(true)
	local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
	local bMyTeamHasHuman = core.MyTeamHasHuman()
	local bBuyTPStone = (core.nDifficulty ~= core.nEASY_DIFFICULTY) or bMyTeamHasHuman

	--For our first frame of this execute
	if bBuyTPStone and core.GetLastBehaviorName(botBrain) ~= core.GetCurrentBehaviorName(botBrain) then
		if nextItemDef:GetName() ~= core.idefHomecomingStone:GetName() then
			--Seed a TP stone into the buy items after 1 min, Don't buy TP stones if we have Post Haste
			local sName = "Item_HomecomingStone"
			local nTime = HoN.GetMatchTime()
			local tItemPostHaste = core.InventoryContains(tInventory, "Item_PostHaste", true)
			if nTime > core.MinToMS(1) and #tItemPostHaste then
				tinsert(behaviorLib.curItemList, 1, sName)
			end

			nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
		end
	end

	if behaviorLib.printShopDebug then
		BotEcho("============ BuyItems ============")
		if nextItemDef then
			BotEcho("BuyItems - nextItemDef: "..nextItemDef:GetName())
		else
			BotEcho("ERROR: BuyItems - Invalid ItemDefinition returned from DetermineNextItemDef")
		end
	end

	if nextItemDef ~= nil then
		core.teamBotBrain.bPurchasedThisFrame = true

		--open up slots if we don't have enough room in the stash + inventory
		local componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
		local slotsOpen = behaviorLib.NumberSlotsOpen(tInventory)

		if behaviorLib.printShopDebug then
			BotEcho("Component defs for "..nextItemDef:GetName()..":")
			core.printGetNameTable(componentDefs)
			BotEcho("Checking if we need to sell items...")
			BotEcho("  #components: "..#componentDefs.."  slotsOpen: "..slotsOpen)
		end

		if #componentDefs > slotsOpen + 1 then --1 for provisional slot
			behaviorLib.SellLowestItems(botBrain, #componentDefs - slotsOpen - 1)
		elseif #componentDefs == 0 then
			behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
		end

		local nGoldAmountBefore = botBrain:GetGold()

		if nextItemDef ~= nil and unitSelf:GetItemCostRemaining(nextItemDef) < nGoldAmountBefore then
      unitSelf:PurchaseRemaining(nextItemDef)
		end

		local nGoldAmountAfter = botBrain:GetGold()
		bGoldReduced = (nGoldAmountAfter < nGoldAmountBefore)

		--Check to see if this purchased item has uncombined parts
		componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
		if #componentDefs == 0 then
			behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
		end
		behaviorLib.addItemBehavior(nextItemDef:GetName())
	end

	bShuffled = behaviorLib.SortInventoryAndStash(botBrain)

	if not bGoldReduced and not bShuffled then
		if behaviorLib.printShopDebug then
			BotEcho("Finished Buying!")
		end
    core.OrderAbility(botBrain, core.unitSelf:GetAbility(12))
		behaviorLib.finishedBuying = true
	end
end

behaviorLib.ShopBehavior["Execute"] = ShopExecuteOverride


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
