if not CLIENT then return end -- nope, sorry

local gat = gace.AddTest

gat("GAceTree: tree item sorter", function(t)
    local tbl = {
        {name = "folder/.git/hooks/applypatch-msg.sample", item={type="file"}},
        {name = "folder/.git/info", item={type="folder"}},
        {name = "folder/.git/index", item={type="file"}},
        {name = "folder", item={type="folder"}},
        {name = "folder/.git/COMMIT_EDITMSG", item={type="file"}},
        {name = "folder/.git/hooks", item={type="folder"}},
        {name = "folder/.git", item={type="folder"}},
    }

    table.sort(tbl, gace.GAceTreeSorter)

    local sortedtbl = {
        {name = "folder", item={type="folder"}},
        {name = "folder/.git", item={type="folder"}},
        {name = "folder/.git/hooks", item={type="folder"}},
        {name = "folder/.git/hooks/applypatch-msg.sample", item={type="file"}},
        {name = "folder/.git/info", item={type="folder"}},
        {name = "folder/.git/COMMIT_EDITMSG", item={type="file"}},
        {name = "folder/.git/index", item={type="file"}},
    }

    t.assertTrue(gace.DeepEquals(tbl, sortedtbl), "sort correctly")
end)
