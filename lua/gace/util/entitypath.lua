gace.entitypath = {}

local folder_ent_names = {
	["cl_init"] = "cl",
	["init"] = "sv",
	["shared"] = "sh",
}

local gm_subentityfolders = {
	["entities"] = true,
	["weapons"] = true,
	["effects"] = true,
}

function gace.entitypath.Analyze(path)
	-- first try to find a folder entity in entities folder
	-- in this case we can even skip the folder_ent_names and guess the realm
	local folder, file = string.match(path, ".-/entities/([^/]+)/([^/]+)%.lua$")
	if folder and file and not gm_subentityfolders[folder] then
		local realm = "sh"
		if string.match(file, "^cl_") then
			realm = "cl"
		elseif string.match(file, "^sv_") then
			realm = "sv"
		end
		return folder, realm
	end
	
	-- if it's a folder ent in other folder with specified name, use that
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
