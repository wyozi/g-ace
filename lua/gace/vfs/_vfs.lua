gace.VFS = gace.VFS or {}

gace.VFS.Capability = {
    READ     = bit.lshift(1, 0),
    WRITE    = bit.lshift(1, 1),
    REALFILE = bit.lshift(1, 2), -- has representation on user filesystem
    STAT     = bit.lshift(1, 3), -- files only; has size()
}

gace.VFS.ReturnCode = {
    SUCCESS      = 0,
    ERROR        = -1, -- generic
    NOT_FOUND    = -2,
    INVALID_TYPE = -3
}
