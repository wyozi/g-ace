-- Default logging mechanism. Simply concats passed arguments converting them to string using "tostring()" if needed
-- "LogMessage" GAce hook can override the whole log system
gace.Log = function(...)
	
	if gace.CallHook("LogMessage", ...) then return end

	local msgtbl = {}
	for _,v in pairs{...} do
		table.insert(msgtbl, tostring(v))
	end

	MsgN("[G-Ace Log] " .. table.concat(msgtbl, ""))
end