-- This file focuses on keeping the file tree in sidebar updated, parsing networked filetree tables etc

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

-- Returns table that is identical to 'large' except has no values that exist in 'sub'
-- Instead of returning an indexed list, this returns a table with same key-value pairs as the "large" table
function ft.SubtractTable(large, sub)
	local ret = {}
	for k,v in pairs(large) do
		if not table.HasValue(sub, v) then
			ret[k] = v
		end
	end
	return ret
end

-- Options for both file and folder tree nodes
function ft.AddTreeNodeOptions(node, filetree)
	node.Label.Think = function(self) self:SetColor(gace.UIColors.frame_fg) end
end

-- Adds right click options etc to given DTree_Node that represents a folder
function ft.AddFolderNodeOptions(node, filetree)

	-- Override expander's doclick to get rid of the annoying slide animation
	node.Expander.DoClick = function() node:SetExpanded(not node.m_bExpanded, true) end

	node.DoRightClick = function()
		local menu = DermaMenu()
		gace.CallHook("FileTreeContextMenu", node, menu, "folder")
		menu:Open()
	end

	local oldthink = node.Think
	node.Think = function(self)
		-- Used to retain expanded status if the node is recreated
		local meta = gace.FileNodeTreeMeta
		if meta then
			local entry = meta[ft.NodeToPath(self)] or {}
			entry.expanded = self.m_bExpanded
			meta[ft.NodeToPath(self)] = entry
		end

		if self.m_bExpanded and node.treetable.pendingListing then
			gace.Log("Listing recfolder ", ft.NodeToPath(self))

			ft.RefreshPath(filetree, ft.NodeToPath(self))

			node.treetable.pendingListing = false
		end

		gace.CallHook("FileTreeFolderNodeThink", self)

		oldthink(self)
	end

	node.Icon.DefaultImage = "icon16/folder.png"
	node.Icon:SetImage(node.Icon.DefaultImage)

	gace.CallHook("OnFileTreeNodeCreated", node, filetree, "folder")
end

-- Adds right click options etc to given DTree_Node that represents a file
function ft.AddFileNodeOptions(node, filetree)
	node.DoClick = function()
		local id = ft.NodeToPath(node)
		gace.OpenSession(id)
	end
	node.DoRightClick = function()
		local menu = DermaMenu()
		gace.CallHook("FileTreeContextMenu", node, menu, "file")
		menu:Open()
	end

	local oldthink = node.Think
	node.Think = function(self)
		-- Used to update the icon based on git status
		gace.CallHook("FileTreeFileNodeThink", self)

		oldthink(self)
	end

	node.Icon.DefaultImage = "icon16/page_white.png"
	node.Icon:SetImage(node.Icon.DefaultImage)

	gace.CallHook("OnFileTreeNodeCreated", node, filetree, "file")
end

local function PaintFileNode(self, w, h)
	-- TODO if this file = currently open file
	--if self.Path == gace.GetSessionId() then
	--	surface.SetDrawColor(127, 255, 127, 140)
	--	surface.DrawRect(0, 0, w, h)
	--end

	gace.CallHook("FileTreeNodePaint", self, w, h)
end

-- Refreshes path in filetree using given tree table
function ft.RefreshPathUsingTree(filetree, path, tree)
	local root = gace.FileNodeTree
	local replace_everything = false

	if path == "" or not root then
		root = {node=filetree, fol={}, fil={}}
		gace.FileNodeTree = root
	end

	local metainfo_cache = gace.FileNodeTreeMeta
	if not metainfo_cache then
		metainfo_cache = {}
		gace.FileNodeTreeMeta = metainfo_cache
	end

	local function AddTreeNode(node, par)
		local parnode = par.node
		if parnode.ChildNodes then parnode.ChildNodes:Remove() parnode.ChildNodes=nil end

		if node.fol then
			local sorted_fol = {}
			for k,v in pairs(node.fol) do
				table.insert(sorted_fol, {k=k, v=v})
			end
			table.sort(sorted_fol, function(a,b) return a.k < b.k end)

			for _, v in pairs(sorted_fol) do
				local foldnm, fold = v.k, v.v

				local folnode = parnode:AddNode(foldnm)
				ft.AddFolderNodeOptions(folnode, filetree)
				ft.AddTreeNodeOptions(folnode, filetree)

				local metacache_entry = metainfo_cache[ft.NodeToPath(folnode)]

				if metacache_entry and metacache_entry.expanded then -- Old folnode table entry was expanded
					folnode:SetExpanded(true)
				else
					folnode:SetExpanded(false)
				end

				local mytbl = {fol={}, fil={}, node=folnode, pendingListing = fold.pendingListing}
				folnode.treetable = mytbl
				par.fol[foldnm] = mytbl

				if fold.pendingListing then
					fold.fil = {"LOADING"}
				end

				AddTreeNode(fold, mytbl)

				-- We're top level
			end
		end
		if node.fil then
			local sorted_fil = {}
			for k,v in pairs(node.fil) do
				table.insert(sorted_fil, {k=k, v=v})
			end
			table.sort(sorted_fil, function(a,b) return a.v < b.v end)

			for _,v in pairs(sorted_fil) do
				local fil = v.v

				local filnode = parnode:AddNode(fil)
				filnode.Path = ft.NodeToPath(filnode)

				filnode.Paint = PaintFileNode

				par.fil[fil] = filnode

				ft.AddFileNodeOptions(filnode, filetree)
				ft.AddTreeNodeOptions(filnode, filetree)
			end
		end
	end

	if path == "" then
		local rootnode = filetree:Root()
		if rootnode.ChildNodes then rootnode.ChildNodes:Remove() rootnode.ChildNodes=nil end
		replace_everything = true
	else
		local pathcomps = path:Split("/")
		for depth,pc in ipairs(pathcomps) do
			-- A hack! If we're trying to traverse a folder in depth 1 (aka direct child of root)
			--  we should create the folder if it doesnt exist and create a node for it
			if depth == 1 and not root.fol[pc] then
				root.fol[pc] = {}
				AddTreeNode({fol={[pc]={}}}, root)
			end
			root = root.fol[pc]
		end
	end

	AddTreeNode(tree, root)
end

-- Sends a request to server to send back a tree of the given path
function ft.RefreshPath(filetree, path)
	gace.ListTree(path, function(_, _, payload)
		if payload.err then return MsgN("Failed to refresh path: ", payload.err) end
		ft.RefreshPathUsingTree(filetree, payload.path, payload.tree)
	end)
end
