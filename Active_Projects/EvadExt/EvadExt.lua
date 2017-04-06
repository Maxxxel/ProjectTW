local forceBlock = {
	["EOW"] = function()
		Order:BlockMovements(true)
	end,
	["GOS"] = function()
		GOS:BlockMovement(true)
	end,
	["SDK"] = function()
		-- waiting for an API to Block Movement from SDK
	end,
	["None"] = function() end
}

function GetOrb()
	return _G.EOWLoaded and "EOW" or _G.GOS and "GOS" or _G.SDK and "SDK" or "None"
end

function BlockExternalMovement() -- Should be used while evading.
	forceBlock[GetOrb()]
end
