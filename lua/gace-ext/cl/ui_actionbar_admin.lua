gace.AddHook("AddActionBarComponents", "ActionBar_AdminCommands", function(comps)
	comps:AddCategory("Admin", Color(150, 40, 27))
	comps:AddComponent {
		text = "VFS",
		width = 90,
		fn = function()
			local sess = gace.GetOpenSession()

			local menu = DermaMenu()

            local csubmenu, csmpnl = menu:AddSubMenu("Create VFolder")
    		csmpnl:SetIcon("icon16/folder_brick.png")

    		local types = {
                ["memory"]      = {},
                ["real-data"]   = {prompt_path = true},
                ["real-gaceio"] = {prompt_path = true, path_example = "./garrysmod"}
            }

    		for tnm,t in pairs(types) do
    			csubmenu:AddOption(tnm, function()
                    local vfs_name, vfs_path
    				gace.ext.ShowTextInputPrompt("VFolder name"):then_(function(nm)
                        vfs_name = nm

                        if not t.prompt_path then return end

                        return gace.ext.ShowTextInputPrompt("VFolder path", nil, t.path_example):then_(function(path)
                            vfs_path = path
                        end)
                    end):then_(function()
                        gace.SendRequest("createvfolder", {name = vfs_name, path = vfs_path, type = tnm}, function(_, _, pl)
                            if pl.err then
                                gace.Log(gace.LOG_ERROR, "Failed to create vfolder: ", pl.err)
                                return
                            end
                            gace.filetree.RefreshPath("")
                        end)
                    end):catch(print)
    			end)
    		end

			menu:Open()

		end,
		enabled = function()
            return LocalPlayer():IsSuperAdmin()
		end
	}
	comps:AddCategoryEnd()
end)
