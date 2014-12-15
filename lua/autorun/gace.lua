gace = gace or {}

-- Include testing stuff
if SERVER then AddCSLuaFile("tests/_gacetests.lua") end
include("tests/_gacetests.lua")
