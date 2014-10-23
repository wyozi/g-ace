gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun", function(comps)
	comps:AddCategory("Run on", Color(142, 68, 173))

	comps:AddComponent {
		text = "Self",
		fn = function()
			luadev.RunOnSelf(gace.GetOpenSession().Content, "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Server",
		fn = function()
			luadev.RunOnServer(gace.GetOpenSession().Content, "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Shared",
		fn = function()
			luadev.RunOnShared(gace.GetOpenSession().Content, "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Clients",
		fn = function()
			luadev.RunOnClients(gace.GetOpenSession().Content, "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Player",
		fn = function()
			local menu = DermaMenu()
			for _,ply in pairs(player.GetAll()) do
				menu:AddOption(ply:Nick(), function()
					luadev.RunOnClient(gace.GetOpenSession().Content, ply, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil and gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "ULX Group",
		fn = function()
			local menu = DermaMenu()
			for group,_ in pairs(ULib.ucl.groups) do
				menu:AddOption(group, function()
					local targetplys = gace.FilterSeq(player.GetAll(), function(x) return x:IsUserGroup(group) end)
					luadev.RunOnClient(gace.GetOpenSession().Content, targetplys, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil and
									ULib ~= nil and
									ULib.ucl ~= nil and
									ULib.ucl.groups ~= nil and
									gace.IsSessionOpen()
							end
	}

	comps:AddCategoryEnd()
end)