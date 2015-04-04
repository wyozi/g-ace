local openPathsRestored = false

gace.AddHook("PostEditorCreated", "RestoreOpenPaths", function()
	-- Lets wait a bit for the editor to load. TODO find a better way to do this than a constant time value
	timer.Simple(1.5, function()
		local openPathsCache = gace.ClientCache:get("openpaths")
		if openPathsCache then
			for _, val in pairs(openPathsCache) do
				gace.filetree.RefreshPath(val)
			end
		end

		openPathsRestored = true
	end)
end)

timer.Create("GAceSaveOpenPaths", 1, 0, function()
	local filetree = gace.GetPanel("FileTree")
	if not IsValid(filetree) then return end
	if not openPathsRestored then return end

	gace.ClientCache:set("openpaths", filetree:ExpandedItemDump(true))
end)