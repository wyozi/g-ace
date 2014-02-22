
local function AddCommand(name, fn)
	concommand.Add(name, function(ply, cmd, args)
		if ply:IsValid() and (game.IsDedicated() or not ply:IsSuperAdmin()) then return ply:ChatPrint("No permission") end
		fn(unpack(args))
	end)
end

local available_types = {
	["gmodio"] = function(name, rootpath, access) gace.SetupGModIOVFolder(name, rootpath, "DATA", access) end,
	["gaceio"] = function(name, rootpath, access) gace.SetupGaceIOVFolder(name, rootpath, access) end,
	["simple"] = function(name, rootpath, access) gace.SetupSimpleVFolder(name, {}, access) end,
}

local function GetPersistentVFS()
	return util.JSONToTable(file.Read("g-ace-vfs.txt", "DATA") or "{}")
end
local function SetPersistentVFS(t)
	file.Write("g-ace-vfs.txt", util.TableToJSON(t))
end

for dtname,dt in pairs(GetPersistentVFS()) do
	local ret, err = pcall(available_types[dt.type], dtname, gace.Path(dt.rootpath), dt.access)
	if not ret then return MsgN("[G-Ace] Adding VFolder failed: ", err) end
end

AddCommand("g-ace-vfs-add", function(name, type, access, rootpath)
	if not name then return MsgN("[G-Ace] Name required!") end
	if not type then return MsgN("[G-Ace] Type required! Types: " .. table.ToString(gace.TableKeysToList(available_types))) end
	if not available_types[type] then return MsgN("[G-Ace] Unknown type! Types: " .. table.ToString(gace.TableKeysToList(available_types))) end

	access = access or "superadmin"
	rootpath = gace.Path(rootpath or "")

	local ret, err = pcall(available_types[type], name, rootpath, access)
	if not ret then return MsgN("[G-Ace] Adding VFolder failed: ", err) end

	local t = GetPersistentVFS()
	t[name] = {type=type, rootpath=rootpath:ToString(), access=access}
	SetPersistentVFS(t)

	MsgN("[G-Ace] VFolder '" .. name .. "' added with access " .. access .. " and rootpath " .. rootpath:ToString() .. ". Run 'g-ace-refresh' to see changes.")
end)

AddCommand("g-ace-vfs-add-temp", function(name, type, access, rootpath)
	if not name then return MsgN("[G-Ace] Name required!") end
	if not type then return MsgN("[G-Ace] Type required! Types: " .. table.ToString(gace.TableKeysToList(available_types))) end
	if not available_types[type] then return MsgN("[G-Ace] Unknown type! Types: " .. table.ToString(gace.TableKeysToList(available_types))) end

	access = access or "superadmin"
	rootpath = gace.Path(rootpath or "")

	local ret, err = pcall(available_types[type], name, rootpath, access)
	if not ret then return MsgN("[G-Ace] Adding VFolder failed: ", err) end

	MsgN("[G-Ace] Temporary VFolder '" .. name .. "' added with access " .. access .. " and rootpath " .. rootpath:ToString() .. ". Run 'g-ace-refresh' to see changes.")
end)

AddCommand("g-ace-vfs-del", function(name)
	if not name then return MsgN("[G-Ace] Name required!") end
	if gace.RemoveVFolder(name) then
		MsgN("[G-Ace] VFolder deleted. Run 'g-ace-refresh' to see changes.")

		local t = GetPersistentVFS()
		t[name] = nil
		SetPersistentVFS(t)
	else
		MsgN("[G-Ace] No such VFolder.")
	end
end)