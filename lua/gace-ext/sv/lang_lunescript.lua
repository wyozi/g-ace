-- LuneScript support
-- Code that starts with "--!lune" is translated to lunescript
-- Depends on https://github.com/LuneScript/lunescript

gace.AddHook("GAceTransformLua", "LuneScript", function(code)

	if code:StartWith("--!lune") then
		if not lunescript then return false, "LuneScript module not installed!" end

		local ast, msg = lunescript.parse(code)
		if not ast then
			return false, "LuneScript error: " .. tostring(msg)
		end

		return true, lunescript.to_lua(ast)
	end
end)
