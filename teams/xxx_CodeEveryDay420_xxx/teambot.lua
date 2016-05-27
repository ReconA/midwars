local _G = getfenv(0)
local object = _G.object

object.myName = 'xxx_CodeEveryDay420_xxx'

object.core     = {}

runfile 'bots/teambot/teambotbrain.lua'
runfile "bots/core.lua"

local core = object.core
local BotEcho = core.BotEcho
------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
--function object:onthinkOverride(tGameVariables)
--  self:onthinkOld(tGameVariables)
--end
--object.onthinkOld = object.onthink
--object.onthink = object.onthinkOverride
--
local unitTeamTarget = nil

function object:GetTeamTarget()
  if unitTeamTarget and unitTeamTarget:IsValid() then
    if self:CanSeeUnit(unitTeamTarget) then
      return self:GetMemoryUnit(unitTeamTarget)
    else
      unitTeamTarget = nil
    end
  end
  return nil
end

function object:SetTeamTarget(target)
  local old = self:GetTeamTarget()
  if old then
    local basePos = core.allyMainBaseStructure:GetPosition()
    if Vector3.Distance2D(basePos, old:GetPosition()) < Vector3.Distance2D(basePos, target:GetPosition()) then
      return
    end
  end
  unitTeamTarget = target
end

--object.nNextPushTime = 35000
--
--function object:GroupAndPushLogic()
--    
--  local nCurrentMatchTime = HoN.GetMatchTime()
--  local nCurrentGameTime = HoN.GetGameTime()
--    
--  if self.nPushState == STATE_IDLE then
--    
--    if nCurrentMatchTime > self.nNextPushTime then
--      --determine target lane
--      local sLane = nil
--      local tLaneUnits = {}
--      local tLaneNodes = {}
--      
--      sLane, tLaneUnits, tLaneNodes = self:RandomPushLane()
--      
--      local unitTarget = core.GetClosestLaneTower(tLaneNodes, core.bTraverseForward, core.enemyTeam)
--      if unitTarget == nil then
--        unitTarget = core.enemyMainBaseStructure
--      end
--      self.unitPushTarget = unitTarget
--      
--      --calculate estimated time to arrive
--      local unitRallyBuilding = core.GetFurthestLaneTower(tLaneNodes, core.bTraverseForward, core.myTeam)
--      if unitRallyBuilding == nil then
--        unitRallyBuilding = core.allyMainBaseStructure
--      end
--      self.unitRallyBuilding = unitRallyBuilding
--      
--      --invalidate our wait timeout
--      self.nGroupWaitTime = nil
--      
--      local vecTargetPos = unitRallyBuilding:GetPosition()
--      for key, hero in pairs(tLaneUnits) do
--        if hero:IsBotControlled() then
--          local nWalkTime = core.TimeToPosition(vecTargetPos, hero:GetPosition(), hero:GetMoveSpeed())
--          local nRespawnTime = (not hero:IsAlive() and hero:GetRemainingRespawnTime()) or 0
--          local nTotalTime = nWalkTime * self.nGroupEstimateMul + nRespawnTime
--          tinsert(self.tArrivalEstimatePairs, {hero, nTotalTime})
--        end
--      end
--      
--      self.nPushStartTime = nCurrentMatchTime
--      self.nPushState = STATE_GROUPING
--    end
--  elseif self.nPushState == STATE_GROUPING then
--    if not self.unitRallyBuilding or not self.unitRallyBuilding:IsValid() then
--      self.nNextPushTime = nCurrentMatchTime
--      self.nPushState = STATE_IDLE
--    elseif self.nGroupWaitTime ~= nil and nCurrentGameTime >= self.nGroupWaitTime then
--      self.nPushState = STATE_PUSHING
--    else
--      local bAllHere = true
--      local bAnyHere = false
--      local vecRallyPosition = self.unitRallyBuilding:GetPosition()
--      for key, tPair in pairs(self.tArrivalEstimatePairs) do
--        local unit = tPair[1]
--        local nTime = tPair[2]
--        if not unit or not nTime then 
--          BotEcho('GroupAndPushLogic - ERROR - malformed arrival esimate pair!')
--        end
--        
--        if Vector3.Distance2DSq(unit:GetPosition(), vecRallyPosition) > self.nGroupUpRadiusSq then
--        
--          if nCurrentMatchTime > self.nPushStartTime + nTime then
--            self.tArrivalEstimatePairs[key] = nil
--          else
--            bAllHere = false
--          end
--          
--        end
--      end
--      
--      if bAllHere then
--        self.nPushState = STATE_PUSHING
--      elseif bAnyHere and self.nGroupWaitTime == nil then
--        self.nGroupWaitTime = nCurrentGameTime + self.nMaxGroupWaitTime
--      end
--    end
--  elseif self.nPushState == STATE_PUSHING then
--    local bEnd = not self.unitPushTarget:IsAlive()
--    
--    if bEnd == false then
--      --if we don't want to end already, see if we have wiped
--      local nHeroesAlive = 0
--      for _, hero in pairs(self.tAllyHeroes) do
--        if hero:IsAlive() then
--          nHeroesAlive = nHeroesAlive + 1
--        end
--      end
--      
--      bEnd = nHeroesAlive <= 3
--    end
--    
--    if bEnd == true then
--      self:BuildLanes()
--      self.nPushState = STATE_IDLE
--      self.nNextPushTime = nCurrentMatchTime + 1000; -- Push right after regroup
--    end
--  end
--  
--end
