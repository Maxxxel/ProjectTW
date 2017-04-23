local forceBlockAllow = function(index)
	return index == "Block" and {
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
	} or index == "Allow" and {
		["EOW"] = function()
			Order:BlockMovements(false)
		end,
		["GOS"] = function()
			GOS:BlockMovement(false)
		end,
		["SDK"] = function()
			-- waiting for an API to Allow Movement from SDK
		end,
		["None"] = function() end
	}
end

function GetOrb()
	return _G.EOWLoaded and "EOW" or _G.GOS and "GOS" or _G.SDK and "SDK" or "None"
end

function BlockExternalMovement() -- Should be used while evading.
	forceBlockAllow("Block")[GetOrb()]
end

function AllowExternalMovement() -- Should be used after evading.
	forceBlockAllow("Allow")[GetOrb()]
end
