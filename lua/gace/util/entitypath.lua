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