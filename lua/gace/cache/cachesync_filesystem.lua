local CacheSyncFS = Middleclass("CacheSyncFS")

function CacheSyncFS:initialize(filename)
	self.filename = filename
end

function CacheSyncFS:onChange(cache, key, val, oldValue)
	local dumped = cache:dumpCache()

	file.Write(self.filename, util.TableToJSON(dumped))
end

function CacheSyncFS:updateCache(cache)
	local table = util.JSONToTable(file.Read(self.filename) or "{}")

	for k,v in pairs(table) do
		cache:set(k, v, true)
	end
end

gace.CacheSyncFS = CacheSyncFS
