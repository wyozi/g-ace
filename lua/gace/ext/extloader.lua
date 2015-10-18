-- Table extensions can use for their own stuff
gace.ext = gace.ext or {}

-- Load single file extensions

local cl_extensions = file.Find("gace-ext/cl/*.lua", "LUA")
local sh_extensions = file.Find("gace-ext/sh/*.lua", "LUA")
local sv_extensions = file.Find("gace-ext/sv/*.lua", "LUA")

for _,ext in pairs(sh_extensions) do
	if SERVER then AddCSLuaFile("gace-ext/sh/" .. ext) end
	include("gace-ext/sh/" .. ext)
end
for _,ext in pairs(cl_extensions) do
	if SERVER then AddCSLuaFile("gace-ext/cl/" .. ext) end
	if CLIENT then include("gace-ext/cl/" .. ext) end
end
for _,ext in pairs(sv_extensions) do
	if SERVER then include("gace-ext/sv/" .. ext) end
end

-- Load extension modules

local _, extmods = file.Find("gace-ext/mod/*", "LUA")
for _,extmod in pairs(extmods) do
	for _,ext in pairs(file.Find("gace-ext/mod/" .. extmod .. "/sh_*.lua", "LUA")) do
		if SERVER then AddCSLuaFile("gace-ext/mod/" .. extmod .. "/" .. ext) end
		include("gace-ext/mod/" .. extmod .. "/" .. ext)
	end
	for _,ext in pairs(file.Find("gace-ext/mod/" .. extmod .. "/cl_*.lua", "LUA")) do
		if SERVER then AddCSLuaFile("gace-ext/mod/" .. extmod .. "/" .. ext) end
		if CLIENT then include("gace-ext/mod/" .. extmod .. "/" .. ext) end
	end
	for _,ext in pairs(file.Find("gace-ext/mod/" .. extmod .. "/sv_*.lua", "LUA")) do
		if SERVER then include("gace-ext/mod/" .. extmod .. "/" .. ext) end
	end
end
