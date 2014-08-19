gace.AddHook("AddPanels", "Editor_AddSideBar", function(frame, basepnl)
	local sb = basepnl:AddSubPanel("SideBar", LEFT)
	sb:SetWide(250)
end) 