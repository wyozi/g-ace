-- Lets just use Garry's hook system

function gace.CallHook(name, ...)
	return hook.Call("GAce" .. name, GAMEMODE, ...)
end
function gace.AddHook(name, id, fn)
	hook.Add("GAce" .. name, id, fn)
end