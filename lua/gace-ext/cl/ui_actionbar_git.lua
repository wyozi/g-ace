gace.AddHook("AddActionBarComponents", "ActionBar_GitCommands", function(comps)
	comps:AddCategory("Git", Color(52, 152, 219))
	comps:AddComponent {
		text = function()
			local sess = gace.GetOpenSession()
			if sess and sess.VFolder.git then
				return string.format("Git mode: %s", (sess.VFolder.git.enabled) and "On" or "Off")
			end

			return "Enable Git"
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

			menu:AddOption("Branch: " .. git.branch, function() end):SetIcon("icon16/arrow_branch.png")
			menu:AddSpacer()
			menu:AddOption("Show status", function()
				local document = "Branch: " .. git.branch .. "\n\n";

				if git.filestatuses then
					for name,status in pairs(git.filestatuses) do
						document = document .. name .. " = " .. status .. "\n";
					end
				end

				gace.OpenSession("git_status_" .. gace.Path(sess.Id):GetVFolder(), {
					content = document
				})
			end):SetIcon("icon16/printer.png")
			menu:AddOption("Show log", function()
				gace.SendRequest("git-log", {path=gace.GetSessionId()}, function(_, _, pl)
					if pl.ret == "Success" then
						local document = "";
						for _,entry in pairs(pl.log) do
							document = document .. string.format("%s %-32s %s \n", entry.Ref:Trim(), entry.Message:Trim(), entry.Author:Trim())
						end

						gace.OpenSession("git_log_" .. gace.Path(sess.Id):GetVFolder(), {
							content = document
						})
					else
						gace.Log(gace.LOG_ERROR, "Git log failed: ", pl.err)
					end
				end)
			end):SetIcon("icon16/printer.png")
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
