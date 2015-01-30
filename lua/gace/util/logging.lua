-- Default logging mechanism. Simply concats passed arguments converting them to string using "tostring()" if needed
-- "LogMessage" GAce hook can override the whole log system
gace.Log = function(...)
	if gace.CallHook("LogMessage", ...) then return end

	MsgC(Color(78, 205, 196), "[G-Ace Log] ")

	local clr
	for _,v in pairs{...} do
		if type(v) == "table" and v.r and v.g and v.b then
			clr = v
		elseif clr then
			MsgC(clr, tostring(v))
		else
			Msg(tostring(v))
		end
	end

	MsgN()
end

local debug_cvar = CreateConVar("gace_debug", "0")
function gace.IsDebug()
	return debug_cvar:GetBool()
end
function gace.Debug(...)
	if gace.IsDebug() then
		gace.Log("[Debug] ", ...)
	end
end
