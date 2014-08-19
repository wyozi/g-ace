gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun", function(comps)
	comps:AddComponent{ text = "Run on", width = 40 }

	comps:AddComponent {
		text = "Self",
		fn = function()
			luadev.RunOnSelf(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil end,
		tt = "Hotkey in editor: F5"
	}
	comps:AddComponent {
		text = "Server",
		fn = function()
			luadev.RunOnServer(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil end,
		tt = "Hotkey in editor: F6"
	}
	comps:AddComponent {
		text = "Shared",
		fn = function()
			luadev.RunOnShared(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil end,
		tt = "Hotkey in editor: F7"
	}
	comps:AddComponent {
		text = "Clients",
		fn = function()
			luadev.RunOnClients(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil end
	}
	comps:AddComponent {
		text = "Player",
		fn = function()
			local menu = DermaMenu()
			for _,ply in pairs(player.GetAll()) do
				menu:AddOption(ply:Nick(), function()
					luadev.RunOnClient(gace.GetSessionContent(), ply, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil end
	}
	comps:AddComponent {
		text = "ULX Group",
		fn = function()
			local menu = DermaMenu()
			for group,_ in pairs(ULib.ucl.groups) do
				menu:AddOption(group, function()
					local targetplys = gace.FilterSeq(player.GetAll(), function(x) return x:IsUserGroup(group) end)
					luadev.RunOnClient(gace.GetSessionContent(), targetplys, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil and
									ULib ~= nil and
									ULib.ucl ~= nil and
									ULib.ucl.groups ~= nil
							end
	}
end)