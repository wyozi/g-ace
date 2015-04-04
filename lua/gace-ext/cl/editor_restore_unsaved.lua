gace.AddHook("OnSessionContentUpdated", "RestoreUnsavedFiles", function(id, content)
    if id:EndsWith(".ot") then return end
    
    -- This hook is called after sess.Content is updated, so we can do this
    local equal_to_saved = gace.GetSession(id):IsSaved()

    local unsaved_files_cache = gace.ClientCache:getOrSet("unsavedfiles", function() return {} end)

    if equal_to_saved then
        unsaved_files_cache[id] = nil
    else
        local tabIndex = gace.tab.GetTabIndex(id)
        unsaved_files_cache[id] = {content = content, tabIndex = tabIndex}
    end

    gace.ClientCache:set("unsavedfiles", unsaved_files_cache)
end)

gace.AddHook("OnRemoteSessionSaved", "RestoreUnsavedFiles", function(id)
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

        local contents = {}

        for id, val in pairs(unsaved_files_cache) do
            local t
            if type(val) == "table" then
                t = {id = id, content = val.content, tabIndex = val.tabIndex or 0}
            else
                t = {id = id, content = val, tabIndex = 0}
            end

            table.insert(contents, t)
        end

        table.SortByMember(contents, "tabIndex", true)

        for _,c in ipairs(contents) do
            gace.OpenSession(c.id, {content = c.content, mark_unsaved = true})
        end
    end)
end)
