gace.AddHook("FileTreeFileNodeThink", "Git_FileNodeIcon", function(node)
    local pathobj = gace.Path(gace.filetree.NodeToPath(node))
    local vfolder = gace.VFolders[pathobj:GetVFolder()]
    if vfolder and vfolder.git and vfolder.git.enabled then
        local filestatuses = vfolder.git.filestatuses
        local img = "icon16/page_white_go.png"

        local pathstr = pathobj:WithoutVFolder():ToString()
        local status = filestatuses and filestatuses[pathstr]
        if status then
            if status == "modified" or status == "renamed" then
                img = "icon16/page_white_edit.png"
            elseif status == "new" then
                img = "icon16/page_white_add.png"
            end
        end
        
        node.Icon:SetImage(img)
    else
        node.Icon:SetImage(node.Icon.DefaultImage)
    end
end)
