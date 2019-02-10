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
	-- if it's a folder ent in other folder with specified name, use that
	local folder, file = string.match(path, ".-([^/]+)/([^/]+)%.lua$")
	if folder and file and folder_ent_names[file] then
		return folder, folder_ent_names[file]
	end
	
	-- try to find a folder entity in entities folder
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
	
	return string.match(path, ".-([^/]+)%.lua$"), "sh"
end


-- Attempt to find the base path (that could be passed to file.Read using LUA)
-- This does some magical guessing using eg. GAMEMODE.FolderName and so on
function gace.entitypath.FindLuaBasePath(path)
	-- is this a FOLDER-SCRIPTEDENTITY in a GAMEMODE
	local folder, entFolder, file = string.match(path, ".-/entities/([^/]+)/([^/]+)/([^/]+)%.lua$")
	if folder and entFolder and file and gm_subentityfolders[folder] then
		return string.format("%s/entities/%s/%s/", GAMEMODE.FolderName, folder, entFolder)
	end
	
	-- is this a FOLDER-SCRIPTEDENTITY in an ADDON
	local folder, entFolder, file = string.match(path, ".-/([^/]+)/([^/]+)/([^/]+)%.lua$")
	if folder and entFolder and file and gm_subentityfolders[folder] then
		return string.format("%s/%s/", folder, entFolder)
	end
	
	-- is this a NORMAL .lua in a GAMEMODE
	local folder = string.match(path, ".-/gamemode/(.-)/[^/]+%.lua$")
	if folder then
		return string.format("%s/gamemode/%s/", GAMEMODE.FolderName, folder)
	end
	
	-- is this a NORMAL .lua in an ADDON
	local folder = string.match(path, ".-lua/(.-)/[^/]+%.lua$")
	if folder then
		return string.format("%s/", folder)
	end
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

-- Modifies include expressions with relative paths in given code to be relative
-- to the lua/ folder rather than the file itself
-- If we can't figure out the base path for given path returns unmodified code
function gace.entitypath.RebaseIncludes(path, code)
	local basePath = gace.entitypath.FindLuaBasePath(path)
	if basePath then
		return string.gsub(code, "include%s?%(?%s?\"([%a%.%d-_]+)\"%s?%)?", function(include)
			return string.format("include(%q)", basePath .. include)
		end)
	end
	return code
end