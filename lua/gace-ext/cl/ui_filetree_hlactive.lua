gace.AddHook("FileTreeFileNodePrePaint", "HighlightActive", function(node, vars)
    if gace.OpenedSessionId == node.NodeId then
        vars.bg = gace.UIColors.treenode_bg_active
    end
end)
