-- This file focuses on keeping the file tree in sidebar updated, parsing networked filetree tables etc

gace.filetree = {}

local ft = gace.filetree

ft.FetchedFolders = {}
gace.AddHook("ClearGAceVariables", "ClearFetchedFolders", function()
	ft.FetchedFolders = {}
end)

function ft.OnNodeClick(id, type)
	if type == "file" then
		gace.OpenSession(id)
	else
		if not ft.FetchedFolders[id] then
			ft.RefreshPath(id)
		end
	end
end

function ft.OnNodeRightClick(id, type)
	local menu = DermaMenu()
	gace.CallHook("FileTreeContextMenu", id, menu, type)
	menu:Open()
end

-- Sends a request to server to send back a tree of the given path
function ft.RefreshPath(path)
	gace.cmd.ls(LocalPlayer(), path):then_(function(t)
		local filetree = gace.GetPanel("FileTree")

		local existing_names = {}

		for _, id in pairs(filetree:QueryItemChildren(path)) do
			local name = id:match("/?([^/]*)$")
			if not t.entries[name] then
				filetree:RemoveItem(id)
			else
				existing_names[name] = true
			end
		end

		for ename,e in pairs(t.entries) do
			local already_exists = existing_names[ename] == true
			if not already_exists then
				local fpath = gace.path.normalize(path .. "/" .. ename)
				filetree:AddItem(fpath, e.type, e)

				local node = filetree:QueryItemComponent(fpath)
				function node:OnClick()
					ft.OnNodeClick(self.NodeId, self.UserObject.type)
				end
				function node:OnRightClick()
					ft.OnNodeRightClick(self.NodeId, self.UserObject.type)
				end

				node:Droppable("gace" .. e.type)

				gace.CallHook("FileTreePostNodeCreation", fpath, node, e.type)
			end
		end

		ft.FetchedFolders[path] = CurTime()
	end, function(err)
		gace.Log(gace.LOG_WARN, "Refreshing path '" .. tostring(path) .. "' failed: ", err)
	end)
end
