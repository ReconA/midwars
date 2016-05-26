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

local STATE_IDLE      = 0
local STATE_GROUPING  = 1
local STATE_PUSHING   = 2
object.nPushState = STATE_IDLE
function object:GroupAndPushLogic()
  self:BuildLanes()
  self.nPushState = STATE_PUSHING
  self.unitPushTarget = core.enemyMainBaseStructure
end



--local STATE_IDLE      = 0
--local STATE_GROUPING  = 1
--local STATE_PUSHING   = 2
--object.nPushState = STATE_PUSHING

--local nGroupDist = 400
--local groupUpDistSq = nGroupDist * nGroupDist
--local nMaxTime = 20000
--local nStartTime = HoN.GetGameTime()

-- Alternate between push and group state. 
-- Conditions for switching from group to push:
--   - All ally heroes are near the grouping point.
--    OR   
--   - 20 seconds have passed since grouping started. 
--
-- Conditions for switching from push to group:
--   - Less than 4 living heroes.
--   AND NOT
--   - Enemy base almost down and we have the heroes near it.
--function object:GroupAndPushLogic()
--  self:BuildLanes()
--  self.unitPushTarget = core.enemyMainBaseStructure
--  self.unitRallyBuilding = core.allyMainBaseStructure
--  local vecPushPosition = self.unitPushTarget:GetPosition()
--  local pushState = object.nPushState
--  local tAllyHeroes = HoN.GetHeroes(core.myTeam)
--    
--  if pushState == STATE_PUSHING then
--    bGroup = false
--    
--    local nAliveHeroes = 0
--    local nHeroesNearObj = 0
--
--    for _, hero in pairs(tAllyHeroes) do
--      if hero:GetPosition() and Vector3.Distance2DSq(hero:GetPosition(), vecPushPosition) < 600*600 then
--        nHeroesNearObj = nHeroesNearObj + 1
--      end
--      if hero:IsAlive() then
--        nAliveHeroes = nAliveHeroes + 1
--      end
--    end
--    
--    
--    if self.unitPushTarget and self.unitPushTarget:GetHealthPercent() and self.unitPushTarget:GetHealthPercent() < (nHeroesNearObj * 0.05) then -- If we are near a low HP base, keep pushing
--      bGroup = false
--    elseif nAliveHeroes < 4 then
--      bGroup = true
--    end
--    
--    if bGroup then
--      object.nPushState = STATE_GROUPING
--      nStartTime  = HoN.GetGameTime()
--    end
--  
--  elseif pushState == STATE_GROUPING then
--    local bAllHere = true
--    if core.enemyMainBaseStructure then
--      local unitRallyBuilding = core.GetClosestAllyTower(core.enemyMainBaseStructure:GetPosition(), 999999999)
--    end
--    
--    if unitRallyBuilding == nil then
--      unitRallyBuilding = core.allyMainBaseStructure
--    end
--    
--    if core.allyMainBaseStructure then
--      BotEcho("MAIN BASE")
--    end
--      
--    local vecRallyPosition = unitRallyBuilding:GetPosition()
    
--    for _, hero in pairs(tAllyHeroes) do
--      if hero and hero:IsValid() and Vector3.Distance2DSq(hero:GetPosition(), vecRallyPosition) > self.nGroupUpRadiusSq then
--        bAllHere = false
--      end
--    end
    
--    local nCurrentTime = HoN.GetGameTime()
--    if bAllHere or nCurrentTime - nStartTime > nMaxTime then
--      object.nPushState = STATE_PUSHING
--      nStartTime = nil
--    end
--    
--  end
--  
--end