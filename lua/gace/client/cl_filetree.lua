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
			ft.RefreshPath(nil, id)
		end
	end
end

function ft.OnNodeRightClick(id, type)
	local menu = DermaMenu()
	gace.CallHook("FileTreeContextMenu", id, menu, type)
	menu:Open()
end

-- Sends a request to server to send back a tree of the given path
function ft.RefreshPath(filetree, path)
	gace.cmd.ls(LocalPlayer(), path):then_(function(t)
		local filetree = gace.GetPanel("FileTree")

		for ename,e in pairs(t.entries) do
			local fpath = gace.path.normalize(path .. "/" .. ename)
			filetree:AddItem(fpath, e.type, e)

			local node = filetree:QueryItemComponent(fpath)
			function node:OnClick()
				ft.OnNodeClick(self.NodeId, self.UserObject.type)
			end
			function node:OnRightClick()
				ft.OnNodeRightClick(self.NodeId, self.UserObject.type)
			end
		end

		ft.FetchedFolders[path] = CurTime()
	end):catch(print)

end
