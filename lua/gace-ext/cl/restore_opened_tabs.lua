
local function SetCacheValue(key, value)
	local cache = gace.ClientCache:getOrSet("opentabs", function() return {} end)

	cache[key] = value

	gace.ClientCache:set("opentabs", cache)
end

gace.AddHook("OnSessionContentUpdated", "RestoreOpenTabs_UpdateUnsaved", function(id, content)
	local sess = gace.GetSession(id)

	-- If content equals to saved content, we should not store them in the cache
	if sess.SavedContent == content then content = nil end
	
	SetCacheValue(id, {content = content})
end)

gace.AddHook("OnSessionOpened", "RestoreOpenTabs_SessionOpened", function(id)
	SetCacheValue(id, {content = nil})
end)

gace.AddHook("OnSessionSaved", "RestoreOpenTabs_ContentSaved", function(id)
	SetCacheValue(id, {content = nil})
end)

gace.AddHook("OnSessionClosed", "RestoreOpenTabs_SessionClosed", function(id)
	SetCacheValue(id, nil)
end)

gace.AddHook("PostEditorCreated", "RestoreOpenTabs_RestoreTabs", function()
	-- Lets wait a bit for the editor to load. TODO find a better way to do this than a constant time value
	timer.Simple(1.5, function()
		local opened_tabs_cache = gace.ClientCache:get("opentabs")
		if not opened_tabs_cache then return end

		-- TODO check if root folder exists in current editor

		for id,tbl in pairs(opened_tabs_cache) do
			if tbl.content then -- File was not saved
				gace.OpenSession(id, {content=tbl.content, mark_unsaved=true})
			else -- File was saved, now we merely open it
				gace.OpenSession(id)
			end
		end
	end)
end)