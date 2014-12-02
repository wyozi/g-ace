gace = gace or {}

local debug_cvar = CreateConVar("gace_debug", "0")
function gace.IsDebug()
	return debug_cvar:GetBool()
end
function gace.Debug(...)
	if gace.IsDebug() then
		MsgN("GACE DEBUG: ", ...)
	end
end

-- Include testing stuff
if SERVER then AddCSLuaFile("tests/_gacetests.lua") end
include("tests/_gacetests.lua")
