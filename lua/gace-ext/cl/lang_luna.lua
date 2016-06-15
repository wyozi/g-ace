-- Hides the Lua file if Luna file with same (no-ext) name exists
gace.AddHook("FileTreeFilterPath", "FilterCompiledLuna", function(path, ft)
	if path:sub(-4) == ".lua" then
		local lunaPath = string.format("%s.luna", path:sub(1, -5))
		if ft:QueryItem(lunaPath) then
			return false
		end
	end
end)

local function isCompiledLunaNode(id, ft)
	if id:match("%.luna$") then
		local luaPath = string.format("%s.lua", id:sub(1, -6))
		if ft:WasPathVisFiltered(luaPath) then
			return true, luaPath
		end
	end
end

local mat_compiled = Material("icon16/page_code.png")

gace.AddHook("FileTreeFileNodePrePaint", "Luna_CompiledIcon", function(node, vars)
	if isCompiledLunaNode(node.NodeId, node:GetParent()) then
		vars.mat_file = mat_compiled
	end
end)

gace.AddHook("FileTreeContextMenu", "AddGoToLunaOption", function(path, menu, nodetype)
	if nodetype ~= "file" then return end

	local ft = gace.GetPanel("FileTree")

	local b, luaPath = isCompiledLunaNode(path, ft)
	if b then
		menu:AddOption("View compiled code", function()
			gace.OpenSession(luaPath)
		end):SetIcon("icon16/page_code.png")
	end
end)