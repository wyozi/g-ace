local matScratch = Material("icon16/page_paintbrush.png")
gace.AddHook("PreDrawTab", "MarkScratchTabs", function(tab, id)
    if id:match("^scratch %d+$") then
        tab.TextLeftPadding = 20
    end
end)
gace.AddHook("PostDrawTab", "MarkScratchTabs", function(tab, id)
    if id:match("^scratch %d+$") then
        surface.SetMaterial(matScratch)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(3, 3, 16, 16)
    end
end)
gace.AddHook("SkipUnsavedClosePrompt", "ScratchFilesClose", function(id)
    if id:match("^scratch %d+$") then
        return true
    end
end)