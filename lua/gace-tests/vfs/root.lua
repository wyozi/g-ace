local gat = gace.AddTest

gat("VFS: Root properties", function(t)
    local root = gace.VFS.VirtualFolder("root", true)
    local sub = gace.VFS.MemoryFolder("subfolder")
    root:addVirtualFolder(sub)

    t.assertEquals(sub:path(), "subfolder", "root should not show up on :path()")

    local normal_ply = gace.CreateVFSFakePly {}

    t.assertTrue(root:hasCapability(gace.VFS.Capability.ROOT), "virtual folder with root param has ROOT capability")

    -- Root node has implicit read perm for plys

    t.assertTrue(root:hasPermission(normal_ply, gace.VFS.Permission.READ), "root virtual folder has implicit read rights for all plys")
    t.assertFalse(sub:hasPermission(normal_ply, gace.VFS.Permission.READ), "root's subfolder doesn't inherit implicit read permission")
end)
