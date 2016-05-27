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

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'

-----------------------------------
--Constants
-----------------------------------

behaviorLib.StartingItems  = {"Item_ManaBattery", "Item_MinorTotem", "Item_MinorTotem", "Item_MarkOfTheNovice", "Item_MarkOfTheNovice", "Item_HealthPotion"}
behaviorLib.LaneItems  = {"Item_PowerSupply", "Item_Marchers", "Item_Steamboots", "Item_HelmOfTheVictim", "Item_Critical1", "Item_ArclightCrown"}
behaviorLib.MidItems = {"Item_WhisperingHelm", "Item_Weapon3", "Item_Critical2", "Item_LifeSteal4"}
behaviorLib.LateItems = {"Item_Critical4", "Item_Morph"}

-- Harass up from ready skills
object.nFullWhip = 0;
object.nVoodooUp = 10;

-- Team group utility. Default is 0.35
behaviorLib.nTeamGroupUtilityMul = 0.45


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
core.tLanePreferences = {Jungle = 0, Mid = 2, ShortSolo = 2, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

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


-- Get the voodoo puppet
local function getPuppet(botBrain, myPos)
  local nRadius = 900
  local tEnemies = core.AssessLocalUnits(botBrain, myPos, nRadius).Enemies

  for _, enemy in pairs(tEnemies) do --If a puppet exists, set it as the target
    if enemy:GetTypeName() == "Pet_PuppetMaster_Ability4" then
      return enemy
    end
  end
end

-- Harass behavior when a puppet exists
local function puppetExistsHarass(botBrain, unitTarget, puppet)

  local bActionTaken = false;
  local unitSelf = core.unitSelf


  -- If the puppet target is far from puppet, cast hold
  local nDistToPuppetSq = getDistance2DSq(puppet, object.puppetTarget)
  local nThreshold = 1000

  if nDistToPuppetSq > (nThreshold * nThreshold) then
    local abilHold = skills.hold
    if not bActionTaken and abilHold and abilHold:CanActivate() then
      unitTarget = object.puppetTarget
      local nTargetDistanceSq = getDistance2DSq(unitSelf, unitTarget)
      local nMyRange = unitSelf:GetAttackRange()
      if nTargetDistanceSq > (nMyRange * nMyRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilHold, puppet)
      end

    end
  end

 -- If the puppet target is near the puppet, cast Puppet Show
  local abilShow = skills.show
  if not bActionTaken and abilShow and abilShow: CanActivate() then
    local nRadius = 200 + abilShow:GetLevel() * 50
    local nearestToFoe = getNearestUnit(botBrain, unitTarget, nRadius)

    if nearestToFoe and nearestToFoe:GetTypeName() == object.sPuppetName then
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

  -- Cast puppet show if the enemy is near some enemy and voodoo is on cooldown. Don't cast if the enemy is held
  local abilShow = skills.show
  if abilShow and abilShow:CanActivate() and not unitTarget:HasState("State_PuppetMaster_Ability1") then
    local nCD = abilShow:GetCooldownTime()
    local nRange = abilShow: GetRange()
    local closestToTarget = getNearestUnit(botBrain, unitTarget, 400) --400 == radius of puppet show
    if nCD < nVoodooCD and nTargetDistanceSq < (nRange * nRange) and closestToTarget then
      bActionTaken = core.OrderAbilityEntity(botBrain, abilShow, unitTarget)
    end
  end

  -- Cast hold on enemy under 50% health. Don't cast if the enemy has crazy puppet status
  if not bActionTaken and unitTarget:GetHealthPercent() < 0.5 and not unitTarget:HasState("State_PuppetMaster_Ability2") then
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
       local teamBotBrain = core.teamBotBrain
       if teamBotBrain.SetTeamTarget then
         teamBotBrain:SetTeamTarget(object.puppetTarget)
       end       
    end
  end
end

-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

-- Hold an nearby enemy hero while retreating
function behaviorLib.CustomRetreatExecute(botBrain)

  local unitSelf = core.unitSelf
  -- Don't cast hold if on high HP
  if unitSelf:GetHealthPercent() > 0.8 then
    return false
  end


  local abilHold = skills.hold
  local nRange = abilHold:GetRange()

  local vecMyPosition = unitSelf:GetPosition()

  if abilHold and abilHold:CanActivate() then

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
  return generics.CustomHarassUtility(hero)
end
-- assign custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


--------------------------------------------------------------
--                    Harass Behavior                       --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none

local function HarassHeroExecuteOverride(botBrain)
  local teamBotBrain = core.teamBotBrain
  if teamBotBrain.GetTeamTarget then
    local teamTarget = teamBotBrain:GetTeamTarget()
  end
    
  local unitTarget = nil
  if teamTarget and core.CanSeeUnit(botBrain, teamTarget) then
    unitTarget = teamTarget
  else
    unitTarget = behaviorLib.heroTarget
  end

  if unitTarget == nil then
    return object.harassExecuteOld(botBrain)  --Target is invalid, move on to the next behavior
  end

  object.lastTarget = unitTarget

  local unitSelf = core.unitSelf

  local bActionTaken = false

  local myPos = unitSelf: GetPosition()

  -- Cast voodoo is possible. Don't cast on low HP targets.
  local abilVoodoo = skills.voodoo
  if abilVoodoo:CanActivate() and unitTarget:GetHealthPercent() < 0.2 then
    bActionTaken = core.OrderAbilityEntity(botBrain, abilVoodoo, unitTarget)
  end

  if not bActionTaken then
    local puppet = getPuppet(botBrain, unitTarget)
    if puppet then
      bActionTaken = puppetExistsHarass(botBrain, unitTarget, puppet)
    else
      bActionTaken = noPuppetExistsHarass(botBrain, unitTarget)
    end
  end

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end

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

  -- if bCourierFound then
  --   core.BotEcho("TRUE")
  -- end
  --
  -- if not bCourierFound then
  --   core.BotEcho("FALSE")
  -- end

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


-- overload the behaviour stock function with the new
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading puppetmaster_main')
