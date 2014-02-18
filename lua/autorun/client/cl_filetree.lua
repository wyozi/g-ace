gace.filetree = {}

local ft = gace.filetree

-- Creates a Path from node (traverses node's parent's until we hit the root and makes a path from them)
function ft.NodeToPath(node, skip_first_node)
	local t = {}

	if not skip_first_node then
		t[1] = node:GetText()
	end

	local p = node:GetParentNode()
	while p do
		if p:GetText() == "" then break end

		table.insert(t, p:GetText())
		p = p.GetParentNode and p:GetParentNode()
	end
	return table.concat(table.Reverse(t), "/")
end

-- Returns table that is same to large except has no values in sub
-- Instead of an indexes list, this returns a table with same key-value pairs as the "large" table
function ft.SubtractTable(large, sub)
	local ret = {}
	for k,v in pairs(large) do
		if not table.HasValue(sub, v) then
			ret[k] = v
		end
	end
	return ret
end

-- Sends a request to server to send back a tree of the given path
function ft.RefreshPath(filetree, path)
	gace.List(path, function(_, _, payload)
		ft.RefreshPathUsingTree(filetree, path, payload.tree)
	end, true)
end

-- Adds right click options etc to given DTree_Node that represents a folder
function ft.AddFolderNodeOptions(node, filetree)
	node.DoRightClick = function()
		local menu = DermaMenu()

		menu:AddOption("Refresh", function()
			ft.RefreshPath(filetree, ft.NodeToPath(node))
		end):SetIcon("icon16/arrow_refresh.png")

		menu:AddOption("Create File", function()
			gace.AskForInput("Filename? Needs to end in .txt", function(nm)
				local filname = ft.NodeToPath(node) .. "/" .. nm
				gace.OpenSession(filname, "", {defens = true})
			end)
		end):SetIcon("icon16/page.png")

		menu:Open()
	end

	local oldthink = node.Think
	node.Think = function(self)
		-- Used to retain expanded status if the node is recreated
		self.treetable.expanded = self.m_bExpanded

		oldthink(self)
	end

	node:Receiver("gacefile", function(self, filepanels, dropped)
		if not dropped then return end

		local mypath = ft.NodeToPath(self)

		-- Files getting moved to this folder
		for _,fp in pairs(filepanels) do
			local path = ft.NodeToPath(fp)
			-- Fetch contents of this file
			gace.Fetch(path, function(_, _, payload)
				if payload.err then return MsgN("Fail to fetch: ", payload.err) end

				-- Delete old file (this is a move, not a copy after all) and save new file with old contents
				gace.Delete(path)
				gace.Save(mypath .. "/" .. fp:GetText(), payload.content)

				-- Refresh both old and new folders
				ft.RefreshPath(filetree, mypath)
				ft.RefreshPath(filetree, ft.NodeToPath(fp, true))
			end)
		end
	end)
end

-- Adds right click options etc to given DTree_Node that represents a file
function ft.AddFileNodeOptions(node, filetree)
	node.DoClick = function()
		local id = ft.NodeToPath(node)
		gace.Fetch(id, function(_, _, payload)
			gace.OpenSession(id, payload.content)
		end)
	end
	node.DoRightClick = function()
		local menu = DermaMenu()

		menu:AddOption("Duplicate", function()
			gace.AskForInput("Filename? Needs to end in .txt", function(nm)
				local filname = ft.NodeToPath(node, true) .. "/" .. nm
				gace.Fetch(ft.NodeToPath(node), function(_, _, payload)
					if payload.err then return MsgN("Failed to fetch: ", payload.err) end
					gace.OpenSession(filname, payload.content, {defens=true})
				end)
			end)
		end):SetIcon("icon16/page_copy.png")

		local csubmenu, csmpnl = menu:AddSubMenu("Delete", function() end)
		csmpnl:SetIcon( "icon16/cross.png" )

		csubmenu:AddOption("Are you sure?", function()
			gace.Delete(ft.NodeToPath(node))
			ft.RefreshPath(filetree, ft.NodeToPath(node, true))
		end):SetIcon("icon16/stop.png")

		menu:Open()
	end
	node:Droppable("gacefile")
	node.Icon:SetImage("icon16/page.png")
end

local function PaintFileNode(self, w, h)
	if self.Path == gace.OpenedSessionId then
		surface.SetDrawColor(127, 255, 127, 140)
		surface.DrawRect(0, 0, w, h)
	end

	-- Collaborators in this file
	local collabs = {}
	for k,v in pairs(gace.CollabPositions) do
		if IsValid(k) and v == self.Path then
			table.insert(collabs, k)
		end
	end

	for idx,c in pairs(collabs) do
		if not IsValid(c.CollabAvatar) then
			c.CollabAvatar = vgui.Create("AvatarImage")
			c.CollabAvatar:SetPlayer(c, 16)
			c.CollabAvatar:SetToolTip(c:Nick())
			c.CollabAvatar.Think = function(self)
				if not IsValid(c) or self:GetParent().Path ~= gace.CollabPositions[c] then
					self:SetParent(nil)
					self:SetVisible(false)
				end
			end
		end
		c.CollabAvatar:SetVisible(true)
		c.CollabAvatar:SetParent(self)
		c.CollabAvatar:SetPos(w-idx*16, 0)
		c.CollabAvatar:SetSize(16, 16)
		--draw.SimpleText(c:Nick():sub(1,1), "DermaDefaultBold", w-idx*10, 2, Color(0, 0, 0))
	end
end

-- Refreshes path in filetree using given tree table
function ft.RefreshPathUsingTree(filetree, path, tree)
	local root = gace.FileNodeTree
	local replace_everything = false

	if path == "" then
		root = {node=filetree, fol={}, fil={}}
		gace.FileNodeTree = root

		local rootnode = filetree:Root()
		if rootnode.ChildNodes then rootnode.ChildNodes:Remove() rootnode.ChildNodes=nil end
		replace_everything = true
	else
		local pathcomps = path:Split("/")
		for _,pc in ipairs(pathcomps) do
			root = root.fol[pc]
		end
	end

	local function AddTreeNode(node, par)
		local parnode = par.node
		if parnode.ChildNodes then parnode.ChildNodes:Remove() parnode.ChildNodes=nil end

		if node.fol then
			for foldnm,fold in pairs(node.fol) do
				local node = parnode:AddNode(foldnm)
				ft.AddFolderNodeOptions(node, filetree)

				local oldnodetable = par.fol[foldnm]
				if oldnodetable then -- Old node table entry was expanded
					node:SetExpanded(oldnodetable.expanded or false)
				elseif par == gace.FileNodeTree then -- We're top level
					node:SetExpanded(true)
				end

				local mytbl = {fol={}, fil={}, node=node}
				node.treetable = mytbl
				par.fol[foldnm] = mytbl

				AddTreeNode(fold, mytbl)

				-- We're top level
			end
		end
		if node.fil then
			for _,fil in pairs(node.fil) do
				local filnode = parnode:AddNode(fil)
				filnode.Path = ft.NodeToPath(filnode)

				filnode.Paint = PaintFileNode

				par.fil[fil] = filnode
				ft.AddFileNodeOptions(filnode, filetree)
			end
		end
	end

	AddTreeNode(tree, root)
end