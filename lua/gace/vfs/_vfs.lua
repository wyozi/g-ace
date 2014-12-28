gace.VFS = gace.VFS or {}

gace.VFS.Capability = {
    READ     = bit.lshift(1, 0),
    WRITE    = bit.lshift(1, 1),
    REALFILE = bit.lshift(1, 2), -- has representation on user filesystem
    STAT     = bit.lshift(1, 3), -- files only; has size()
    ROOT     = bit.lshift(1, 4), -- is not included in path() etc
}

gace.VFS.Permission = {
    READ     = bit.lshift(1, 0),
    WRITE    = bit.lshift(1, 1),
}

gace.VFS.ServerPermission = gace.VFS.Permission.READ + gace.VFS.Permission.WRITE

gace.VFS.ErrorCode = {
    ERROR          = "error", -- generic
    NOT_FOUND      = "not found",
    INVALID_TYPE   = "invalid type",
    ALREADY_EXISTS = "already exists",
    ACCESS_DENIED  = "access denied",
}
