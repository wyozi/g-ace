gace.entitypath = {}

local folder_ent_names = {
	["cl_init"] = "cl",
	["init"] = "sv",
	["shared"] = "sh",
}

function gace.entitypath.Analyze(path)
	local folder, file = string.match(path, ".-([^/]+)/([^/]+)%.lua$")
	if folder and file and folder_ent_names[file] then
		return folder, folder_ent_names[file]
	end
	return string.match(path, ".-([^/]+)%.lua$"), "sh"
end

-- Finds includes in code
-- List of what kind of includes are found:
--    include("shared.lua")
--    include("init.lua")
--    include( "cl_init.lua" )
--    include"init2.lua"
function gace.entitypath.FindIncludes(code)
	local t = {}

	for inc in string.gmatch(code, "include%s?%(?%s?\"([%a%.%d-_]+)\"%s?%)?") do
		table.insert(t, inc)
	end

	return t
end
