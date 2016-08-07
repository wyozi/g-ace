local folderSENTFiles = {
	["cl_init.lua"] = [[include "shared.lua"

]],
	["init.lua"] = [[AddCSLuaFile "cl_init.lua"
AddCSLuaFile "shared.lua"
include "shared.lua"

]],
	["shared.lua"] = [[ENT.Type = "anim"

]],
}

gace.AddHook("FileTreeContextMenu", "FileTree_AddPresetCreationOptions", function(path, menu, nodetype)
	if nodetype ~= "folder" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	local csubmenu, csmpnl = menu:AddSubMenu("Create from Preset", function() end)
	csmpnl:SetIcon( "icon16/folder_brick.png" )
	
	local function CreateFolder(fpath)
		return ATPromise(function(res)
			gace.SendRequest("mkdir", {path = fpath}, function(_, _, pl)
				if pl.err then
					res:reject(pl.err)
					return
				end
				res:resolve(fpath)
			end)
		end)
	end

	csubmenu:AddOption("Folder-SENT (cl_init,init,shared)", function()
		gace.ext.ShowTextInputPrompt("Entity folder name", function(nm)
			if nm:match("%.lua$") then
				gace.Log(gace.LOG_ERROR, "Refusing to create entity folder with lua suffix")
				return
			end

			CreateFolder(path .. "/" .. nm):then_(function()
				local writes = {}
				for fn, fc in pairs(folderSENTFiles) do
					local fpath = path .. "/" .. nm .. "/" .. fn
					writes[#writes + 1] = gace.cmd.write(LocalPlayer(), fpath, fc)
				end

				return ATPromise(writes):all()
			end):then_(function()
				ft.RefreshPath(path)
			end):catch(function(err)
                gace.Log(gace.LOG_ERROR, "SENT Folder creation failed: ", err)
			end)
		end)
	end):SetIcon("icon16/controller.png")
end)