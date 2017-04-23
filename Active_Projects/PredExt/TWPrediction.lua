-------------------------------------------------------------------------
--[[ Changelog:
    0.01: Skeleton
--]]
-------------------------------------------------------------------------
_G.TWPrediction_Version = 0.01

--Requirements: See To Do at the bottom of the Script
require '2DGeometry'
require 'Pathfinding'

--Spell identifier, used for spell.type
TWP_SkillShot = 1 --can hit just 1 target
TWP_AOESkillShot = 2 --can hit multiple targets
TWP_AOESpell = 3 --no travelZone, because casted on ground or self

-------------------------------------------------------------------------
--Variables
-------------------------------------------------------------------------
local sqrt, pow = math.sqrt, math.pow
-------------------------------------------------------------------------
--Stuff
-------------------------------------------------------------------------
function GetDistanceSqr(Pos1, Pos2)
    local Pos2 = Pos2 or myHero.pos
    local dx = Pos1.x - Pos2.x
    local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
    return dx^2 + dz^2
end

--Default on 2D its faster but less accurate
local function GetDistance(p1, p2)
    return sqrt(math.pow((p2.x - p1.x),2) + pow((p2.y - p1.y),2))
end

local function GetDistance3D(p1, p2)
    return sqrt(math.pow((p2.x - p1.x),2) + pow((p2.y - p1.y),2) + pow((p2.z - p1.z),2))
end

class("TWPrediction")
-------------------------------------------------------------------------
--Init
-------------------------------------------------------------------------
function TWPrediction:__init()

end
-------------------------------------------------------------------------
--Update
-------------------------------------------------------------------------
function TWPrediction:Update()

end
-------------------------------------------------------------------------
--Variables
-------------------------------------------------------------------------
function TWPrediction:Variables()
  self.PredictionDamage = {}
end
-------------------------------------------------------------------------
--Menu
-------------------------------------------------------------------------
function TWPrediction:Menu()

    self.Menu = MenuElement({type = MENU, id = "TWPrediction", name = "TWPrediction", leftIcon=Icons["C"]})
    
end
-------------------------------------------------------------------------
--OnTick
-------------------------------------------------------------------------
function TWPrediction:OnTick()
  
end
-------------------------------------------------------------------------
--GetPred
-------------------------------------------------------------------------
function TWPrediction:GetPred()
  
  return CastPos, HitChance
end
-------------------------------------------------------------------------
--GetPredPos
-------------------------------------------------------------------------
function TWPrediction:GetPredPos()
  
  return unitPredPos
end
-------------------------------------------------------------------------
--SpellReactionTime
-------------------------------------------------------------------------
function TWPrediction:SpellReactionTime()
  
  return SRT
end

--[[++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Maxxxels attempt

    Requirements for 'spell' --> need to go into a spell init Function (TWPrediction:SetSpell() ?)
        spell = {
            delay = number,
            range = number,
            width = number,
            speed = number,
            hitBox = boolean,
            type = number/identifier
        }
--]]

--GetMaxMovingrange: returns the maximum range a 'unit' can move in 'time'
function TWPrediction:GetMaxMovingRange(unit, time)
    return unit.ms * time
end

--GetMaxReactionTime: returns the maximum time a 'unit' has to dodge a 'spell'
function TWPrediction:GetMaxReactionTime(unit, spell) --Same as :SpellReactionTime()?
    return spell.delay + (unit.distance - (spell.hitbox and unit.boundingRadius or 0)) / spell.speed --add Ping difference?
end

--GetCheckPoint: returns a point in direction of given 'activeRayNum'. Think about a Cake you want to slice in 'maxRayCasts' pieces. Give every piece a number and then check their direction.
function TWPrediction:GetCheckPoint(unit, maxRayCasts, activeRayNum)
    local cP = nil
    --Same functionality as 2-official-WardAwareness.lua? Talk to WhiteHat
    return cP
end

--GetMovingArea: returns a polygonal representation of the moving area from 'unit' if 'spell' is shot
function TWPrediction:GetMovingArea(unit, spell)
    local mRT = self:GetMaxReactionTime(unit, spell)
    local mMR = self:GetMaxMovingRange(unit, mRT)
    local Area = nil
    
    if mRT and mMR then
        Area = Polygon()
        for i = 1, _MENU_VALUE_FOR_RAY_CASTS_ do
            local cP = self:GetCheckPoint(unit, _MENU_VALUE_FOR_RAY_CASTS_, i) --Depends on '_MENU_VALUE_FOR_RAY_CASTS_', minimum is 8 for (N, NE, E, SE, S, SW, W, NW), maximum depends on final performance
            --Find endPoint of #Ray and add it to Polygon list
            if cP then
                Area.points[#Area.points + 1] = _PATHFINDING_COMES_HERE_WITH_GIVEN_MAXIMUM_RANGE_AND_CHECKPOINT --Edit Pathfinding to return a Point with given range
            end
        end
    end
    
    return Area
end

function TWPrediction:CreateTravelZone(spell)
    if spell.type ~= 3 then --1 and 2 are both LineSkillShots, we can ignore the AOE Part here because its only needed for Collision checks
        local hitSpot = Circle(_SPELL_END_POS_, spell.width) --include boundingRadius of myHero and unit?
        local tunnel = Polygon(_4_SPOTS_REPRESENTING_THE_SPELL_TRAVEL_PATH)
        local result = nil --Combine hitSpot with tunnel into a Polygon
        
        return result
    else
        return = Circle(myHero, spell.width) --include boundingRadius of myHero and unit?
    end
    
    return nil
end

function TWPrediction:GetHitArea(unit, spell)
    local Area = nil
    --[[
        HitArea is defined by spell.range, spell.width, unit.distance and unit.boundingRadius+spell.hitBox
        
        Simple Attempt #1
            Create A Polygon for the Spell Travelzone
    --]]
    local Area = self:CreateTravelZone(spell) --Polygon/Circle
    
    return Area
end

function GetBestMatchingSpot(spot1, spot2)
    local finalSpot, finalArea = nil, nil
    
    return finalSpot, finalArea
end

--GetPrediction: returns best castPos and hitChance to cast 'spell' on 'unit', 'spell' is a table holding diff. Values
function TWPrediction:GetPrediction(unit, spell)
    local castPos, hitChance = nil, 0
    local mA = self:GetMovingArea(unit, spell) --Polygon
    local hA = self:GetHitArea(unit, spell) --Polygon
    --Compare both Areas and find Spot with biggest equality in Size
    if mA and hA then
        local cP, oA = self:GetBestMatchingSpot(mA, hA)
        if cP and oA then
            castPos = cP
            hitChance = oA * 100 / mA
        end
    end
    
    return castPos, hitChance
end

--[[
    End of Maxxxels attempt
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++]]

-------------------------------------------------------------------------
--CollisionStatus
-------------------------------------------------------------------------
function TWPrediction:CollisionStatus()
 
  return false
end
-------------------------------------------------------------------------
--MinionCollision
-------------------------------------------------------------------------
function TWPrediction:MinionCollision()

end
-------------------------------------------------------------------------
--HeroCollision
-------------------------------------------------------------------------
function TWPrediction:HeroCollision()

end
-------------------------------------------------------------------------
--EachCollision
-------------------------------------------------------------------------
function TWPrediction:EachCollision()

  return true
end
-------------------------------------------------------------------------
--SpellCollision
-------------------------------------------------------------------------
function TWPrediction:SpellCollision()

end
-------------------------------------------------------------------------
--IsInvincible
-------------------------------------------------------------------------
function TWPrediction:IsInvincible()

  return false
end
-------------------------------------------------------------------------
--OnAnimation
-------------------------------------------------------------------------
function TWPrediction:OnAnimation(unit, animation)

end
-------------------------------------------------------------------------
--OnProcessAttack
-------------------------------------------------------------------------
function TWPrediction:OnProcessAttack()

end
-------------------------------------------------------------------------
--PredictHealth
-------------------------------------------------------------------------
function TWPrediction:PredictHealth()

  return health
end
-------------------------------------------------------------------------
--GetAADmg
-------------------------------------------------------------------------
function TWPrediction:GetAADmg()

end
-------------------------------------------------------------------------
--OnUpdateBuff
-------------------------------------------------------------------------
function TWPrediction:OnUpdateBuff()

end
-------------------------------------------------------------------------
--OnRemoveBuff
-------------------------------------------------------------------------
function TWPrediction:OnRemoveBuff()

end
-------------------------------------------------------------------------
--Level
-------------------------------------------------------------------------
function TWPrediction:Level(spell)
  return myHero:GetSpellData(spell).level
end

-------------------------------------------------------------------------
--To Do
-------------------------------------------------------------------------
--[[
    -math.pow?
    -replace ^2 with x * x
    -wrapper for Positions (Vector2, Vector3, unit)
    -add Menu for #Ray casts
    -Create own class for Polys if 2DGeometry is not loaded, to save performance?
    -include small and simple Pathfinding into TWPrediction? Just needs AStar, no need for Theta i see here
--]]
