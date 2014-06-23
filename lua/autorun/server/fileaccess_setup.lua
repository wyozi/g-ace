gace.VirtualFolders = gace.VirtualFolders or {}

function gace.SetupRawVFolder(id, access, data)
	gace.VirtualFolders[id] = {
		ffunc=data.filebrowser_func,
		svfunc=data.save_func,
		delfunc=data.delete_func,
		mkdirfunc=data.mkdir_func,
		access=access,
		description=data.description
	}
end

function gace.RemoveVFolder(id)
	local r = gace.VirtualFolders[id] ~= nil
	gace.VirtualFolders[id] = nil
	return r
end

-- Setups a simple fully virtual folder, which is simply based on a table, where folders are subtables and files are strings.
function gace.SetupSimpleVFolder(id, tbl, access, data)
	data = data or {}

	local function TraversePath(path)
		path = path:WithoutVFolder()

		-- Parent folder, folder
		local parfolder, folder = tbl, tbl

		for _,v in ipairs(path.Parts) do
			if folder then parfolder = folder end
			if not folder then break end

			folder = folder[v]
		end
		return folder, parfolder
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not folder then return false, "Doesn't exist" end

			if type(folder) == "table" then
				local keys = gace.TableKeys(folder)
				return "folder",
						-- Files
						gace.Map(
							gace.FilterSeq(gace.SortedTable(gace.TableKeys(folder)), function(x) return type(folder[x]) == "string" end),
							function(nm) return curpath + nm end
						),
						-- Folders
						gace.Map(
							gace.FilterSeq(gace.SortedTable(gace.TableKeys(folder)), function(x) return type(folder[x]) == "table" end),
							function(nm) return curpath + nm end
						)
			end
			return "file", folder, 0, 0
		end,
		mkdir_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not parfolder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = {}
		end,
		save_func = function(curpath, content)
			local folder, parfolder = TraversePath(curpath)
			if not parfolder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = content
		end,
		delete_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not folder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = nil
		end,
		description = data.description
	})

end

-- Setups a folder that uses Garry's Mod's IO lib (file.Write, file.Read etc)
function gace.SetupGModIOVFolder(id, root, path, access)

	local vfolderpath = gace.Path(id)

	-- Returns a function that maps source files (e.g. foo.txt) to full paths (e.g. VFolder/root/foo.txt)
	local function PathAdder(tpath)
		return function(src)
			return vfolderpath + tpath + src
		end
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if not file.Exists(curpath:ToString(), path) then
				return false, "Doesn't exist"
			end

			local is_dir = curpath:IsRoot() or file.IsDir(curpath:ToString(), path)
			if is_dir then
				local files, folders = file.Find(curpath:ToString() .. "/*", path)
				gace.Debug("Crawling ", curpath:ToString() .. "/*", " results to ", #files, " files and ", #folders, " folders")
				
				return "folder", gace.Map(gace.SortedTable(files), PathAdder(curpath)), gace.Map(gace.SortedTable(folders), PathAdder(curpath))
			end
			return "file", file.Read(curpath:ToString(), path), file.Size(curpath:ToString(), path), file.Time(curpath:ToString(), path)
		end,
		save_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			if not curpath:GetFile():EndsWith(".txt") then
				return false, "Path must end in .txt"
			end
			file.Write(curpath:ToString(), content)
			return true
		end,
		mkdir_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			file.CreateDir(curpath:ToString())
			return true
		end,
		delete_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			--if not file.Exists(curpath:ToString(), path) then
			--	return false, "Doesn't exist"
			--end

			file.Delete(curpath:ToString())
			return true
		end
	})
end

-- GaceIO support (https://github.com/wyozi/g-ace-io)
local module_loaded = pcall(require, "gaceio") and (gaceio ~= nil)

function gace.SetupGaceIOVFolder(id, root, access)
	if not module_loaded then
		error("Trying to setup a GaceIO VFolder when GaceIO module isn't loaded")
	end

	local vfolderpath = gace.Path(id)

	-- Returns a function that maps source files (e.g. foo.txt) to full paths (e.g. VFolder/root/foo.txt)
	local function PathAdder(tpath)
		return function(src)
			return vfolderpath + tpath + src
		end
	end
	-- Turns path into a string that can be passed to gaceio
	local function GIOPath(path)
		return "./garrysmod/" .. path:ToString()
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if not gaceio.Exists(GIOPath(curpath)) then
				return false, "Doesn't exist"
			end

			local is_dir = curpath:IsRoot() or gaceio.IsFolder(GIOPath(curpath))
			if is_dir then
				local files, folders = gaceio.List(GIOPath(curpath))
				if not files then
					return false, folders
				end
				return "folder", gace.Map(gace.SortedTable(files), PathAdder(curpath)), gace.Map(gace.SortedTable(folders), PathAdder(curpath))
			end
			return "file", gaceio.Read(GIOPath(curpath)), 0, 0
		end,
		save_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.Write(GIOPath(curpath), content)
			return true
		end,
		mkdir_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.CreateFolder(GIOPath(curpath))
			return true
		end,
		delete_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.Delete(GIOPath(curpath))
			return true
		end
	})
end

--gace.SetupVFolder("Data", "", "DATA", "superadmin")
--gace.SetupGModIOVFolder("EpicJB", gace.Path("epicjb/"), "DATA", "superadmin")

--gace.SetupSimpleVFolder("test", {}, "superadmin")

--pcall(function()
	--gace.SetupGaceIOVFolder("gaceiotest", gace.Path("lua"), "superadmin")
--end)