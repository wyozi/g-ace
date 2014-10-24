gace.AddHook("OnSessionContentUpdated", "RestoreUnsavedFiles", function(id, content)
	local unsaved_files_cache = gace.ClientCache:getOrSet("unsavedfiles", function() return {} end)

	unsaved_files_cache[id] = content

	gace.ClientCache:set("unsavedfiles", unsaved_files_cache)
end)

gace.AddHook("OnSessionSaved", "RestoreUnsavedFiles", function(id)
	local unsaved_files_cache = gace.ClientCache:getOrSet("unsavedfiles", function() return {} end)

	unsaved_files_cache[id] = nil

	gace.ClientCache:set("unsavedfiles", unsaved_files_cache)
end)

gace.AddHook("OnSessionClosed", "RestoreUnsavedFiles", function(id)
	local unsaved_files_cache = gace.ClientCache:getOrSet("unsavedfiles", function() return {} end)

	unsaved_files_cache[id] = nil

	gace.ClientCache:set("unsavedfiles", unsaved_files_cache)
end)

gace.AddHook("PostEditorCreated", "RestoreUnsavedFiles", function()
	-- Lets wait a bit for the editor to load. TODO find a better way to do this than a constant time value
	timer.Simple(1.5, function()
		local unsaved_files_cache = gace.ClientCache:get("unsavedfiles")
		if not unsaved_files_cache then return end

		-- TODO check if root folder exists in current editor

		for id,content in pairs(unsaved_files_cache) do
			gace.OpenSession(id, {content=content})

			-- We don't want the file to appear to be already saved
			gace.GetSession(id).SavedContent = nil
		end
	end)
end)