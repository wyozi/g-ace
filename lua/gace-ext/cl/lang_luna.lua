-- Hides the Lua file if Luna file with same (no-ext) name exists
gace.AddHook("FileTreeFilterPath", "FilterCompiledLuna", function(path, ft)
	if path:sub(-4) == ".lua" then
		local lunaPath = string.format("%s.luna", path:sub(1, -5))
		if ft:QueryItem(lunaPath) then
			return false
		end
	end
end)

local mat_compiled = Material("icon16/page_code.png")
gace.AddHook("FileTreeFileNodePrePaint", "Luna_CompiledIcon", function(node, vars)
	if node.NodeId:match("%.luna$") then
		local luaPath = string.format("%s.lua", node.NodeId:sub(1, -6))
		if node:GetParent():WasPathVisFiltered(luaPath) then
			vars.mat_file = mat_compiled
		end
	end
end)