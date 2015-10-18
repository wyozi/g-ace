local req = {}
net.Receive("GAce_DataShare", function(len, cl)
	table.insert(req, {
		from = net.ReadEntity(),
		type = net.ReadString(),
		data = net.ReadTable()
	})

	gace.Log(gace.LOG_INFO, "Received new DataShare request")
end)

local function Do(r)
	if r.type == "path" then
		gace.OpenSession(r.data.path)
	elseif r.type == "snippet" then
		gace.OpenSession("snippet_" .. os.time() .. "_" .. r.from:SteamID64(), {content = r.data.code, mark_unsaved = true})
	end
end

gace.AddHook("AddActionBarComponents", "ActionBar_DataShare", function(comps)
	comps:AddCategory("Data Share", Color(144, 198, 149), 75)
	comps:AddComponent {
		text = "Data Share",
		width = 100,
		fn = function()
			local menu = DermaMenu()
			menu:AddOption("Incoming requests:", function()end):SetImage("icon16/transmit.png")
			menu:AddSpacer()

			for _,r in pairs(req) do
				menu:AddOption(r.type .. " from " .. r.from:Nick(), function()
					table.RemoveByValue(req, r)
					Do(r)
				end)
			end

			menu:Open()
		end
	}
	comps:AddCategoryEnd()
end)
