function gace.CreateTabPanel()
	local tabs = vgui.Create("DHorizontalScroller")
	tabs.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.tab_border)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	tabs:SetOverlap(-1)

	local tabsel = vgui.Create("GAceTabSelector", tabs)
	tabs:AddPanel(tabsel)

	return tabs
end

function gace.GetTabFor(id)
	return _u.detect(gace.GetPanel("Tabs").Panels, function(pnl)
		return pnl.SessionId == id
	end)
end

function gace.CreateTab(id)
	if gace.GetTabFor(id) then return end

	local btn = vgui.Create("GAceTab", gace.Tabs)
	btn:Setup(id)

	local tabs = gace.GetPanel("Tabs")
	tabs:AddPanel(btn)
end

gace.AddHook("OnSessionOpened", "Editor_KeepTabsUpdated", function(id)
	gace.CreateTab(id)
end)

gace.AddHook("OnSessionClosed", "Editor_KeepTabsUpdated", function(id)
	local tabs = gace.GetPanel("Tabs")

	local tab = gace.GetTabFor(id)
	if tab then
		local prev_tab = table.FindPrev(tabs.Panels, tab)
		local set_session
		if prev_tab and prev_tab.SessionId then
			set_session = prev_tab.SessionId
		end

		tab:Remove()
		table.RemoveByValue(tabs.Panels, tab) -- uhh, a hack
		tabs:InvalidateLayout()

		if set_session then
			gace.OpenSession(set_session)
		end
	end
end)
