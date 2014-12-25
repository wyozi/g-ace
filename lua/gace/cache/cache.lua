local Cache = Middleclass("Cache")

function Cache:initialize()
	self.changeListeners = {}
end

-- Core methods

function Cache:exists(key) end
function Cache:get(key) end
function Cache:set(key, val, is_raw_set) end

-- Returns cache as table
function Cache:dumpCache() end

-- Utility methods

function Cache:getOrSet(key, generator)
	if self:exists(key) then
		return self:get(key)
	end
	local val = generator()
	self:set(key, val)
	return val
end

function Cache:addChangeListener(obj)
	if type(obj) == "function" then
		obj = {onChange = obj}
	end

	table.insert(self.changeListeners, obj)
end

function Cache:notifyChangeListeners(key, val, oldValue)
	local is_add_event = oldValue ~= nil
	local is_del_event = val == nil

	local listeners = self.changeListeners
	for i=1, #listeners do
		local l = listeners[i]

		if is_add_event and l.onAdd then
			l:onAdd(self, key, val)
		end
		if is_del_event and l.onDelete then
			l:onDelete(self, key)
		end
		l:onChange(self, key, val, old_value)
	end
end

gace.Cache = Cache
