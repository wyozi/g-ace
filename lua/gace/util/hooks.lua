-- Hook system used by gace extensions.

gace.Hooks = gace.Hooks or {}
local hooks = gace.Hooks

function gace.CallHook(name, ...)
	local hks = hooks[name]
	if not hks then return end

	for i=1,#hks do
		local a, b, c, d, e, f, g = hks[i].fn(...)
		if a ~= nil then return a, b, c, d, e, f, g end
	end
end
function gace.AddHook(name, id, fn)
	if not hooks[name] then hooks[name] = {} end

	-- If hook id already exists, let's replace that hook with our new one
	local old_hook_key
	for k,hk in pairs(hooks[name]) do
		if hk.id == id then
			old_hook_key = k
		end
	end
	hooks[name][old_hook_key or (#hooks[name]+1)] = {id=id, fn=fn}
end
