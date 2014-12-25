-- A mixin that adds a simple variable based name with accessors.

gace.VFS.SimpleName = {
    setName = function(self, name)
        self._name = name
    end,
    name = function(self)
        return self._name or ""
    end
}
