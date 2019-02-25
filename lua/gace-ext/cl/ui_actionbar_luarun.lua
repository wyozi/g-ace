gace.AddHook("AddActionBarComponents", "ActionBar_LuaRun", function(comps)
	comps:AddCategory("Run on", Color(142, 68, 173))

	local function CreateRequest(op, target)
		local sess = gace.GetOpenSession()
		
		local codeId = ("gace://%s"):format(sess.Id)
		local code = sess.Content
		gace.SendRequest(op, {code = code, codeId = codeId, target = target}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, op .. " failed: ", pl.err)
			else
				gace.Log(op .. " done!")
			end
		end)
	end

	comps:AddComponent {
		text = "Client",
		fn = function()
			CreateRequest("lua-runself")
		end,
		splitFn = function(menu)
			for _,p in pairs(player.GetAll()) do
				menu:AddOption(p:Nick(), function()
					CreateRequest("lua-runtarget", p)
				end)
			end
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Server",
		fn = function()
			CreateRequest("lua-runsv")
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Shared",
		fn = function()
			CreateRequest("lua-runsh")
		end,
		enabled = function() return gace.IsSessionOpen() end
	}
	comps:AddComponent {
		text = "Clients",
		fn = function()
			CreateRequest("lua-runcl")
		end,
		enabled = function() return gace.IsSessionOpen() end
	}

	comps:AddCategoryEnd()
end)
