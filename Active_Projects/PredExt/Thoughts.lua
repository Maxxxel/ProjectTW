--[[
    Just some thoughts about the Prediction
--]]

function MaxMovingRange(unit, time)
  --account for ping + order delays tards
  --from Tosh ^_^
  return unit.ms * time
end

function MaxMovingTime(unit, spellData)
  return spellData.delay + spellData + (unit.distance / spellData.speed) --option to add hitBox to substract it from unit.distance, PING?
end

function GetMovingArea(unit, spellData)
  local time = MaxMovingTime(unit, spellData)
  local range = MaxMovingRange(unit, time)
  local Area = nil
  --[[
      Now we know how far unit COULD walk, but there are walls and objects he cant walk, so we need to substract them from the final Area
      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        Idea #1:
          Create a 8-ray Polygon, each rays length == range
          Combine endPoints
          Substract Objets and walls from the Polygon to get the Moving Area

          (Note: to walk around objects the unit needs more time, this wont get into account here)
          ++: Fast
          --: inaccurate

        Idea #2:
          Create a 8-ray Polygon, each rays length == range
          Create 8 Paths to the endPoints of the rays with pathfinding Lib, where maxLength == range
          Combine endPoints to get the Moving Area
          ++: Precise
          --: Needs more time and power
    
        (Generally Note: #rays can be increased in Menu for better Areas but needs more time and power, 8 is minimum)
      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --]]
    
  return Area
end

function GetBestSpot(unit, spellData)
  local Area = GetMovingArea(unit, spellData)
  local bestSpot = nil
  if Area then
  --[[
      Now we got the Moving Area we need to get the best Spot
      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        Way #1:
          Simply get the Middlepoint by math and shoot at it
          ++: Fast
          --: inaccurate
        
        Way #2:
          Get the Middlepoint by math but increase the chance a bit by some factors:
            -basePos
            -facePos
            -towerPos
            -lastMovePos
            -posToMyHero
            -favoritePos (need to track his dodge history)
          ++: Precise
          --: Needs more time and power
      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --]]
  end
    
  return bestSpot
end

function CastSpell(unit, spellData)
  local predPos = GetBestSpot(unit, spellData)
  if predPos then
    --castSpell
  end
end    
