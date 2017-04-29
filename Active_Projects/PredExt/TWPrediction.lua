-------------------------------------------------------------------------
--[[ Changelog:
    0.01: Skeleton
    0.02: Added GetArea
    0.03: Added Pathfinding to GetArea
    0.04: Improved preProcessing
    '---> Bugs:
            -Slow (AStar)
            -Unaccurate Sometimes (Lines 227 - 255)
    0.05: Added Clock Mode (Line 140)
--]]
-------------------------------------------------------------------------
_G.TWPrediction_Version = 0.04
--Requirements: See To Do at the bottom of the Script
require '2DGeometry' --https://github.com/Maxxxel/GOS/blob/master/ext/Common/2DGeometry.lua
require 'MapPosV2' --Summoner Rift only: https://github.com/Maxxxel/GOS/blob/master/ext/Common/MapPosV2.lua
local bh = require 'BinaryHeap' --https://github.com/Maxxxel/GOS/blob/master/ext/Common/BinaryHeap.lua
--Spell identifier, used for spell.type
TWP_SkillShot = 1 --can hit just 1 target
TWP_AOESkillShot = 2 --can hit multiple targets
TWP_AOESpell = 3 --no travelZone, because casted on ground or self
TWP_CONE = 4 --Talon W
TWP_CURVE = 5 --Diana
-------------------------------------------------------------------------
--Variables
-------------------------------------------------------------------------
local sqrt, pow, floor, modf, insert, remove, sin, cos = math.sqrt, math.pow, math.floor, math.modf, table.insert, table.remove, math.sin, math.cos
local gridSize = 50
local grrr = 0.01744444
local Offset = {
    [1] = {x = 0,   y = 1},     --Top
    [2] = {x = 1,   y = 0},     --Right
    [3] = {x = 0,   y = -1},    --Down
    [4] = {x = -1,  y = 0},     --Left
    [5] = {x = 1,   y = 1},     --TopRight
    [6] = {x = -1,  y = 1},     --TopLeft
    [7] = {x = 1,   y = -1},    --DownRight
    [8] = {x = -1,  y = -1}     --DownLeft
}
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
local function GetDistance(A, B)
    A = A.pos or A
    B = B.pos or B

    return sqrt((A.x - B.x) * (A.x - B.x) + ((A.z or A.y) - (B.z or B.y)) * ((A.z or A.y) - (B.z or B.y)))
end

local function GetDistance3D(p1, p2)
    return sqrt(pow((p2.x - p1.x),2) + pow((p2.y - p1.y),2) + pow((p2.z - p1.z),2))
end

class("AStar")

function AStar:StartSession()
    if not self.started then
        self.started = true
        self.N = {}
    end
end

function AStar:StopSession()
    self.started = false
    self.N = nil
end

function AStar:GetNeighbors(node, gNode)
    local Ns = {}

    for i = 1, #Offset do
        local Off = Offset[i]
        local N = {x = node.x + Off.x * gridSize, y = node.y, z = node.z + Off.y * gridSize}
        
        if not isWall(N) then
            N.id = tostring(N.x .. N.z)
            N.parent = node
            N.g = node.g + GetDistance(N, node)
            N.h = GetDistance(N, gNode)
            N.f = N.g + N.h
            self.Queue:push(N)
        end
    end

    return Ns
end

function AStar:FindPath(start, goal, maxLength)
    self.Queue = bh()
    local sNode, gNode = {x = start.x, y = start.y, z = start.z}, {x = goal.x, y = goal.y, z = goal.z}
    local visited = {}
    local pre = nil
    sNode.g = 0
    sNode.f = 0
    sNode.parent = nil
    sNode.id = tostring(sNode.x .. sNode.z)
    gNode.id = tostring(gNode.x .. gNode.z)
    self.Queue:push(sNode)

    while not self.Queue:empty() do
        local cNode = self.Queue:pop()
        if visited[cNode.id] then goto continue end
        visited[cNode.id] = true

        if cNode.id == gNode.id then
            break
        end

        if cNode.g > maxLength then
            pre = cNode
            break
        end

        self:GetNeighbors(cNode, gNode)
        ::continue::
    end

    --BuildPath
    local test = pre or gNode
    local Path = {}

    while test do
        insert(Path, test)
        test = test.parent
    end

    return Path
end

class("Area")

local clock = true
function Area:GetArea(unit, range, qual)
    AStar:StartSession()
    local start = unit.pos or unit
    local turn = 0
    local Quality = qual or 8
    local Add = 360 / Quality
    local Result = Polygon()
    local preProcess = {}
    local visited = {}
    local final = {}

    if not clock then
        for i = 1, Quality do
            turn = turn + Add
            local Check = nil
            local multi = turn * grrr

            for _ = 0.1, 1, .025 do
                local Vec = Vector(range * sin(multi), 0, range * cos(multi)):Normalized() * range * _
                Check = Vector(start) + Vec

                if isWall(Check) then
                    local Vec2 = Vector(range * sin(multi), 0, range * cos(multi)):Normalized() * range
                    insert(preProcess, {x = Check.x, y = Check.y, z = Check.z, target = {x = start.x + Vec2.x, y = Check.y, z = start.z + Vec2.z}})
                    
                    goto continue
                end
            end

            insert(final, Check)
            ::continue::
        end

        local endSpot = {}
        for i = 1, #preProcess do
            local blocked = preProcess[i]
            insert(final, blocked)
            local Path = AStar:FindPath(unit, blocked, range)
            local Dist = GetDistance(unit, blocked)
            if Path and #Path > 2 and Path[1].g > Dist and not endSpot[Path[1].x .. Path[1].z] then
                endSpot[Path[1].x .. Path[1].z] = true
                for j = 1, #Path do
                    local P = Path[j]
                    if P and P.g and P.g > Dist then
                        insert(final, P)
                    end
                end
            end
        end

        endSpot = nil
        preProcess = nil

        local c = 0
        local i = 1
        while true do
            c = c + 1
            local P = final[i]
            -- Draw.Text(i, Vector(P.x, 0, P.z):To2D())
            if not visited[i] then
                visited[i] = true
                insert(Result.points, P)

                local nearest, length, gibbon = nil, 9999, 0
                for j = 1, #final do
                    local Q = final[j]

                    if not visited[j] then
                        local Dist = GetDistance(P, Q)
                        if Dist < length then
                            length = Dist
                            nearest = Q
                            gibbon = j
                        end
                    end
                end

                if nearest then
                    i = gibbon
                end
            end

            if c == 50 then break end
        end

        AStar:StopSession()
    else
        for i = 1, Quality do
            turn = turn + Add
            local Check = start
            local multi = turn * grrr

            for _ = .1, 1, .025 do
                local Vec = Vector(range * sin(multi), 0, range * cos(multi)):Normalized() * range * _
                Check = Vector(start) + Vec

                if isWall(Check) then
                    break
                end
            end

            insert(Result.points, Check)
        end
    end

    return Result
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
    if spell.type == 1 or spell.type == 2 then --1 and 2 are both LineSkillShots, we can ignore the AOE Part here because its only needed for Collision checks
        local hitSpot = Circle(_SPELL_END_POS_, spell.width) --include boundingRadius of myHero and unit?
        local tunnel = Polygon(_4_SPOTS_REPRESENTING_THE_SPELL_TRAVEL_PATH)
        local result = nil --Combine hitSpot with tunnel into a Polygon
        
        return result
    elseif spell.type == 4 then
    elseif spell.type == 5 then
    else
        return Circle(myHero, spell.width) --include boundingRadius of myHero and unit?
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
    -Create own class for Polygon/Circle and the only needed methods if 2DGeometry is not loaded, to save performance?
    -include small and simple Pathfinding into TWPrediction? Just needs AStar, no need for Theta i see here
    -lineOfSight before Pathfinding?
--]]
