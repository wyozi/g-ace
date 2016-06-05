local function AddMenu(menu, name, fn)
	local csubmenu, csmpnl = menu:AddSubMenu(name, function() end)
	csmpnl:SetIcon("icon16/transmit.png")

	for _,v in pairs(player.GetAll()) do
		csubmenu:AddOption(v:Nick(), function()
			fn(v)
		end)
	end
end

gace.AddHook("FileTreeContextMenu", "DataShare", function(path, menu, nodetype)
	if nodetype ~= "file" then return end

	AddMenu(menu, "Share path with", function(v)
		net.Start("GAce_DataShare")
		net.WriteEntity(v)
		net.WriteString("path")
		net.WriteTable { path = path }
		net.SendToServer()
	end)
end)

gace.AddHook("EditorContextMenu", "DataShare", function(menu, data)
	AddMenu(menu, "Share path to this row with", function(v)
		net.Start("GAce_DataShare")
		net.WriteEntity(v)
		net.WriteString("path")
		net.WriteTable { path = gace.GetSessionId(), row = data.cursorpos.row }
		net.SendToServer()
	end)

	AddMenu(menu, "Share selected text with", function(v)
		net.Start("GAce_DataShare")
		net.WriteEntity(v)
		net.WriteString("snippet")
		net.WriteTable { code = data.selection_text or "" }
		net.SendToServer()
	end)
end)
