gace.AddHook("AddActionBarComponents", "ActionBar_GitCommands", function(comps)
	comps:AddCategory("Git", Color(52, 152, 219))
	comps:AddComponent {
		text = function()
			local sess = gace.GetOpenSession()
			local is_on = sess and sess.VFolder.git and sess.VFolder.git.enabled
			return string.format("Git mode: %s", is_on and "On" or "Off")
		end,
		width = 90,
		fn = function()
			local sess = gace.GetOpenSession()
			local vfolder = sess.VFolder

			local git = vfolder.git

			if not git then
				gace.SendRequest("git-status", {path=vfolder.Name}, function(_, _, pl)
					if pl.err then
						gace.Log(gace.LOG_ERROR, "Failed to start git: ", pl.err)
						git = {enabled = false}
						vfolder.git = git
					elseif pl.ret == "Success" then
						git = {enabled = pl.git_enabled}
						vfolder.git = git
						if git.enabled then
							git.branch = pl.git_branch
						end
					end
				end)

				return
			end

			local menu = DermaMenu()

			menu:AddOption("Git information:", function() end):SetIcon("icon16/information.png")
			menu:AddOption("Branch: " .. git.branch, function() end):SetIcon("icon16/arrow_branch.png")
			menu:AddSpacer()
			--[[menu:AddOption("Print diff", function()
				gace.SendRequest("git-diff", {path=gitpath}, function(_, _, pl)
					if pl.ret == "Success" then
						gace.OpenSession("git-diff_" .. gace.Path(id):GetFile() .. "_" .. os.time(), pl.diff)
					end
				end)
			end)]]
			menu:AddOption("Commit all changes", function()
				gace.ext.ShowTextInputPrompt("Enter a commit message", function(nm)
					gace.SendRequest("git-commitall", {path=gace.GetSessionId(), msg=nm}, function(_, _, pl)
						if pl.ret == "Success" then
							gace.Log("Commit succesful")
						else
							gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
						end
					end)
				end)
			end)
			menu:AddOption("Push to upstream", function()
				gace.SendRequest("git-push", {path=gace.GetSessionId()}, function(_, _, pl)
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
			return sess and (not sess.VFolder.git or sess.VFolder.git.enabled ~= false)
		end
	}
	comps:AddCategoryEnd()
end)
