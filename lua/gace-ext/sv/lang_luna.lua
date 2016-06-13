-- Luna support
-- Code that starts with "--!luna" or has .luna extension is considered Luna code
-- Depends on https://github.com/wyozi-gmod/gmod-luna

gace.AddHook("GAceTransformLua", "Luna", function(code, id)
	if code:StartWith("--!luna") or (id and id:EndsWith(".luna")) then
		if not luna then return false, "Luna not installed!" end

		local stat, lua = pcall(luna.TranspileCode, code)

		if not stat then
			return false, "Luna error: " .. tostring(lua)
		end

		return true, lua
	end
end)
