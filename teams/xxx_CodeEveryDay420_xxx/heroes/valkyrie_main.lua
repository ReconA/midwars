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

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'


behaviorLib.StartingItems = {"Item_HealthPotion", "Item_ManaBattery", "Item_PretendersCrown"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_PowerSupply", "Item_Intelligence5", "Item_Replenish", "Item_Steamboots"}
behaviorLib.MidItems = {"Item_Pierce", "Item_Lightning1", "Item_Pierce 3"}
behaviorLib.LateItems = {"Item_Wingbow", "Item_Evasion", "Item_Weapon3", "Item_BehemothsHeart"}

-- Team group utility. Default is 0.35
behaviorLib.nTeamGroupUtilityMul = 0.45


--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
object.tSkills = {
  1, 0, 0, 2, 0,
  3, 0, 2, 2, 2,
  3, 1, 1, 1, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4,
}

local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.call = unitSelf:GetAbility(0)
    skills.javelin = unitSelf:GetAbility(1)
    skills.leap = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.call and skills.javelin and skills.leap and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  local nPoints = unitSelf:GetAbilityPointsAvailable()
  if nPoints <= 0 then
    return
  end

  local nLevel = unitSelf:GetLevel()
  for i = nLevel, (nLevel + nPoints) do
    unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
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

  local addBonus = 0
  if EventData.Type == "Attack" then
    local unitTarget = EventData.TargetUnit
    if EventData.InflictorName == "Projectile_Valkyrie_Ability2" and unitTarget:IsHero() then
      addBonus = addBonus + 50
    end
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

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

--------------------------------------------------------------
--                    Harass Behavior                       --
--------------------------------------------------------------

local function CustomHarassUtilityFnOverride(target)
  local nUtility = 0
--  Stun is checked in Generics CustomHarassUtilityFnOverride()
--  if target:IsStunned() then
--    nUtility = nUtility + 50
--  end
  local call = skills.call
  if call and call:CanActivate() then
    nUtility = nUtility + 10
  end

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf
  local bActionTaken = false

  local call = skills.call
  if call and call:CanActivate() and Vector3.Distance2D(unitTarget:GetPosition(), unitSelf:GetPosition()) < 650 then
    bActionTaken = core.OrderAbility(botBrain, call)
  end

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

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

--------------------------------------------------------------
--                    Arrow Behavior                       --
--------------------------------------------------------------

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
local function PositionSelfLogicOverride(botBrain)
  local vecDesiredPos, unitTarget = PositionSelfLogicOld(botBrain)
  vecDesiredPos = core.AdjustMovementForTowerLogic(vecDesiredPos)
  return vecDesiredPos, unitTarget
end
behaviorLib.PositionSelfLogic = PositionSelfLogicOverride

local function DetermineArrowTarget(arrow)
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = arrow:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and generics.IsFreeLine(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local arrowTarget = nil
local function ArrowUtility(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() then
    local unitTarget = DetermineArrowTarget(javelin)
    if unitTarget then
      arrowTarget = unitTarget:GetPosition()

      return 60
    end
  end
  arrowTarget = nil
  return 0
end

local function ArrowExecute(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() and arrowTarget then
    return core.OrderAbilityPosition(botBrain, javelin, arrowTarget)
  end
  return false
end
local ArrowBehavior = {}
ArrowBehavior["Utility"] = ArrowUtility
ArrowBehavior["Execute"] = ArrowExecute
ArrowBehavior["Name"] = "Arrowing"
tinsert(behaviorLib.tBehaviors, ArrowBehavior)

BotEcho('finished loading valkyrie_main')
