local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

object.generics = {}
local generics = object.generics

BotEcho("loading xxx_CED_xxx generics ..")


-- Adjust harass utility for all heroes.
function generics.CustomHarassUtility(target)
  local nUtil = 0
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local unitSelf = core.unitSelf
  local myPos = unitSelf:GetPosition()

  nUtil = nUtil - (1 - unitSelf:GetHealthPercent()) * 100

  if target:IsChanneling() or target:IsDisarmed() or target:IsImmobilized() or target:IsPerplexed() or target:IsSilenced() or target:IsStunned() or unitSelf:IsStealth() then
    nUtil = nUtil + 50
  end

  local unitsNearby = core.AssessLocalUnits(object, myPos,100)


  if core.NumberElements(unitsNearby.AllyHeroes) < 2 then
    nUtil = nUtil - 26
    
    if core.GetClosestEnemyTower(myPos, 720) then
      nUtil = nUtil - 100
    end

    for id, creep in pairs(unitsNearby.EnemyCreeps) do
      local creepPos = creep:GetPosition()
      if(creep:GetAttackType() == "ranged" or Vector3.Distance2D(myPos, creepPos) < 20) then
        nUtil = nUtil - 20
      end
    end
  end

  return nUtil
end

function generics.IsFreeLine(pos1, pos2)
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 50 * 50
  for _, ally in pairs(tAllies) do
    local posAlly = ally:GetPosition()
    local x3, y3 = posAlly.x, posAlly.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      return false
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

BotEcho("Finished loading xxx_CED_xxx generics ..")
