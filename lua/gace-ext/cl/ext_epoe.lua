hook.Add("EPOEAddLinkPatterns", "GAce_AddEPOEPattern", function(t)
	table.insert(t, "gace://[^%s%\":]+")
end)

hook.Add("EPOEOpenLink", "GAce_HandleEPOEPattern", function(link)
	local gacepath = link:match("^gace://(.*)$")
	if gacepath then
		
		gace.ShowEditor()
		gace.OpenSession(gacepath)
		
		return true
	end
end)