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

gace.AddHook("HandleNetMessage", "HandleGitStatusUpdates", function(netmsg)
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    if op == "git_updstatus" then
        for file,status in pairs(payload) do
            local pathobj = gace.Path(file)
            local vfoldername = pathobj:GetVFolder()

            if status == "empty" then status = nil end

            local vfolder = gace.VFolders[vfoldername]
            if vfolder and vfolder.git then
                vfolder.git.filestatuses = vfolder.git.filestatuses or {}
                vfolder.git.filestatuses[pathobj:WithoutVFolder():ToString()] = status
            end
        end
    end
end)
