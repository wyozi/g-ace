-- Default logging mechanism. Simply concats passed arguments converting them to string using "tostring()" if needed
-- "LogMessage" GAce hook can override the whole log system

gace.LOG_ERROR = Color(255, 0, 0)
gace.LOG_WARN = Color(255, 127, 0)
gace.LOG_SUCCESS = Color(0, 255, 0)
gace.LOG_INFO = Color(170, 255, 255)

local clr_white = Color(255, 255, 255)
local clr_prefix = Color(78, 205, 196)
local clr_debug = Color(235, 151, 78)
gace.Log = function(...)
	if gace.CallHook("LogMessage", ...) then return end

	MsgC(clr_prefix, "[G-Ace Log] ")

	local clr = clr_white
	for _,v in pairs{...} do
		if type(v) == "table" and v.r and v.g and v.b then
			clr = v
		else
			MsgC(clr, tostring(v))
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
		gace.Log(clr_debug, "[Debug] ", clr_white, ...)
	end
end
