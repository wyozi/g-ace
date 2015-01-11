-- Table extensions can use for their own stuff
gace.ext = gace.ext or {}

local cl_extensions = file.Find("gace-ext/cl/*.lua", "LUA")
local sh_extensions = file.Find("gace-ext/sh/*.lua", "LUA")
local sv_extensions = file.Find("gace-ext/sv/*.lua", "LUA")

for _,ext in pairs(cl_extensions) do
	if SERVER then AddCSLuaFile("gace-ext/cl/" .. ext) end
	if CLIENT then include("gace-ext/cl/" .. ext) end
end
for _,ext in pairs(sh_extensions) do
	if SERVER then AddCSLuaFile("gace-ext/sh/" .. ext) end
	include("gace-ext/sh/" .. ext)
end
for _,ext in pairs(sv_extensions) do
	if SERVER then include("gace-ext/sv/" .. ext) end
end
