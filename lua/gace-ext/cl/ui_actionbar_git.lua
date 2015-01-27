gace.AddHook("AddActionBarComponents", "ActionBar_GitCommands", function(comps)
	comps:AddCategory("Git", Color(52, 152, 219))
	comps:AddComponent {
		text = function()
			local sess = gace.GetOpenSession()
			if sess and sess.VFolder.git then
				if sess.VFolder.git.enabled then
					return string.format("Git [%s]", (sess.VFolder.git.branch))
				else
					return "Git [unavailable]"
				end
			end

			return "Git"
		end,
		width = 100,
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
			end):SetIcon("icon16/book.png")
			menu:AddOption("Show log", function()
				gace.SendRequest("git-log", {path=vfolder.Name}, function(_, _, pl)
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
			end):SetIcon("icon16/book_addresses.png")

			menu:AddOption("Show diff: HEAD-Workdir", function()
				gace.SendRequest("git-diff-headwd", {path=vfolder.Name}, function(_, _, pl)
					if pl.ret == "Success" then
						local document = pl.diff;

						gace.OpenSession("git_diff_headwd_" .. gace.Path(sess.Id):GetVFolder(), {
							content = document,
							mode = "ace/mode/diff"
						})
					else
						gace.Log(gace.LOG_ERROR, "Git diff-headwd failed: ", pl.err)
					end
				end)
			end):SetIcon("icon16/arrow_divide.png")

			menu:AddOption("Commit added files", function()
				gace.ext.ShowTextInputPrompt("Enter a commit message", function(nm)
					gace.SendRequest("git-commit", {path=vfolder.Name, msg=nm}, function(_, _, pl)
						if pl.ret == "Success" then
							gace.Log("Commit succesful")
						else
							gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
						end
					end)
				end)
			end):SetIcon("icon16/book_go.png")
			menu:AddOption("Add all and commit", function()
				gace.ext.ShowTextInputPrompt("Enter a commit message", function(nm)
					gace.SendRequest("git-commitall", {path=vfolder.Name, msg=nm}, function(_, _, pl)
						if pl.ret == "Success" then
							gace.Log("Commit succesful")
						else
							gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
						end
					end)
				end)
			end):SetIcon("icon16/book_go.png")
			menu:AddOption("Push to upstream", function()
				gace.SendRequest("git-push", {path=vfolder.Name}, function(_, _, pl)
					if pl.ret == "Success" then
						gace.Log("Push succesful")
					else
						gace.Log(gace.LOG_ERROR, "Commit failed: ", pl.err)
					end
				end)
			end):SetIcon("icon16/book_previous.png")

			menu:Open()

		end,
		enabled = function()
			local sess = gace.GetOpenSession()
			return sess and (not sess.VFolder.git or sess.VFolder.git.enabled ~= false)
		end
	}
	comps:AddCategoryEnd()
end)
