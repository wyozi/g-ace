gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun", function(comps)
	comps:AddCategory("Run on", Color(142, 68, 173))

	local function CreateRequest(op, code)
		gace.SendRequest(op, {code = code}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, op .. " failed: ", pl.err)
			else
				gace.Log(op .. " done!")
			end
		end)
	end

	comps:AddComponent {
		text = "Self",
		fn = function()
			CreateRequest("lua-runself", gace.GetOpenSession().Content)
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Server",
		fn = function()
			CreateRequest("lua-runsv", gace.GetOpenSession().Content)
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Shared",
		fn = function()
			CreateRequest("lua-runsh", gace.GetOpenSession().Content)
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Clients",
		fn = function()
			CreateRequest("lua-runcl", gace.GetOpenSession().Content)
		end,
		enabled = function() return gace.IsSessionOpen() end
	}

	comps:AddCategoryEnd()
end)
