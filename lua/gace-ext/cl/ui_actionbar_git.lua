gace.AddHook("AddActionBarComponents", "ActionBar_GitCommands", function(comps)
	comps:AddCategory("Git", Color(52, 152, 219))
	comps:AddComponent {
		text = function()
			local sess = gace.GetOpenSession()
			local is_on = sess and sess.git and sess.git.enabled
			return string.format("Git mode: %s", is_on and "On" or "Off")
		end,
		width = 90,
		fn = function()
			local sess = gace.GetOpenSession()
			local gitpath = gace.Path(gace.GetSessionId()):GetVFolder()

			if not sess.git then
				gace.SendRequest("git-status", {path=gitpath}, function(_, _, pl)
					if pl.err then
						gace.Log(gace.LOG_ERROR, "Failed to start git: ", pl.err)
						sess.git = {enabled = false}
					elseif pl.ret == "Success" then
						sess.git = {enabled = pl.git_enabled}
						if sess.git.enabled then
							sess.git.branch = pl.git_branch
						end
					end
				end)

				return
			end

			local menu = DermaMenu()

			menu:AddOption("Git information:", function() end):SetIcon("icon16/information.png")
			menu:AddOption("Branch: " .. sess.git.branch, function() end):SetIcon("icon16/arrow_branch.png")
			menu:AddSpacer()
			--[[menu:AddOption("Print diff", function()
				gace.SendRequest("git-diff", {path=gitpath}, function(_, _, pl)
					if pl.ret == "Success" then
						gace.OpenSession("git-diff_" .. gace.Path(sess.id):GetFile() .. "_" .. os.time(), pl.diff)
					end
				end)
			end)]]
			menu:AddOption("Commit all changes", function()
				gace.ext.ShowTextInputPrompt("Enter a commit message", function(nm)
					gace.SendRequest("git-commitall", {path=gitpath, msg=nm}, function(_, _, pl)
						if pl.ret == "Success" then
							gace.Log("Committed to branch ", pl.branch, ". Files changed: ", pl.fcount)
						else
							gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
						end
					end)
				end)
			end)
			menu:AddOption("Push to upstream", function()
				gace.SendRequest("git-push", {path=gitpath}, function(_, _, pl)
					if pl.ret == "Success" then
						gace.Log("Push succesful")
					else
						gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
					end
				end)
			end)

			menu:Open()

		end,
		enabled = function()
			local sess = gace.GetOpenSession()
			return sess and (not sess.git or sess.git.enabled ~= false)
		end
	}
	comps:AddCategoryEnd()
end)