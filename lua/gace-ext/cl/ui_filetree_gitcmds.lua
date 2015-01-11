
gace.AddHook("FileTreeContextMenu", "FileTree_AddGitCommands", function(path, menu, nodetype)
    if nodetype ~= "file" then return end

    local ft = gace.filetree -- Shortcut to filetree library

    menu:AddOption("Git: Add to index", function()
        gace.SendRequest("git-add", {path=path}, function(_, _, pl)
            if pl.ret == "Success" then
                gace.Log("Succesfully added " .. path)
            else
                gace.Log(gace.LOG_ERROR, "Add to index failed: ", pl.err)
            end
        end)
    end):SetIcon("icon16/book_add.png")
end)
