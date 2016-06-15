local cvar_showhiddenFiles = CreateConVar("gace_showhiddenfiles", "0", FCVAR_ARCHIVE)

local function nodeVisFilter(path, ft)
	if cvar_showhiddenFiles:GetBool() then
		return true
	end

	local filter = gace.CallHook("FileTreeFilterPath", path, ft)
	if filter == nil then
		return true
	end
	return filter
end

gace.AddHook("AddPanels", "Editor_AddFileTree", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	gace.FileNodeTree = nil

	local scroll = vgui.Create("DScrollPanel")

	local filetree = vgui.Create("GAceTree")
	filetree:Dock(TOP)
	scroll:AddItem(filetree)

	sb:StorePanelId("FileTree", filetree)

	filetree:SetNodeVisibilityFilter(nodeVisFilter)

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(gace.GetOption("root_path"))

	sb:AddDocked("FileTreeScroll", scroll, FILL)
end)
