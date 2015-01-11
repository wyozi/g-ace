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

--- Returns a table that automatically updates cache whenever you edit a value
-- Uses __newindex, so don't setmetatable or do anything stupid
function Cache:getDynTable(key, create_if_nonexistent)
	local t
	if create_if_nonexistent then
		t = self:getOrSet(key, function() return {} end)
	else
		t = self:get(key)
	end

	if type(t) ~= "table" then return end

	setmetatable(t, {
		__newindex = function(t_self, t_key, t_val)
			rawset(t_self, t_key, t_val)
			self:set(key, t)
		end,
	})

	return t
end

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
