function gace.CreateTabPanel()
	local pnl = vgui.Create("DPanel")
	pnl:SetPaintBackground(false)

	local tabs = vgui.Create("DHorizontalScroller", pnl)
	tabs:Dock(FILL)
	tabs.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.tab_border)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	tabs:SetShowDropTargets(true)
	tabs:MakeDroppable("GAceTabs")
	tabs:SetOverlap(-1)

	local tabsel = vgui.Create("GAceTabSelector", pnl)
	tabsel:Dock(LEFT)

	pnl.Scroller = tabs

	return pnl
end

gace.tab = {}

function gace.tab.GetScroller()
	return gace.GetPanel("Tabs").Scroller
end
function gace.tab.GetPanels()
	return gace.tab.GetScroller().Panels
end

function gace.tab.GetById(id)
	return _u.detect(gace.tab.GetPanels(), function(pnl)
		return pnl.SessionId == id
	end)
end
gace.GetTabFor = gace.tab.GetById -- alias

function gace.tab.GetFilenameCount(fname)
	return _u.reduce(gace.tab.GetPanels(), 0, function(old, pnl)
		if pnl.FileName == fname then return old + 1 end
		return old
	end)
end

function gace.tab.Create(id)
	if gace.GetTabFor(id) then return end

	local btn = vgui.Create("GAceTab", gace.Tabs)
	btn:Setup(id)

	local tabs = gace.tab.GetScroller()
	tabs:AddPanel(btn)

	-- In case there are duplicate filenames
	tabs:InvalidateChildren()
end
gace.CreateTab = gace.tab.Create -- alias

function gace.tab.Remove(id)
	local tabs = gace.tab.GetScroller()

	local tab = gace.GetTabFor(id)
	if tab then
		local panels = gace.tab.GetPanels()

		-- Find tab to open after closing this session
		local prev_tab = table.FindPrev(panels, tab)
		local set_session
		if prev_tab and prev_tab.SessionId and prev_tab.SessionId ~= id then
			set_session = prev_tab.SessionId
		end

		tab:Remove()
		table.RemoveByValue(panels, tab) -- uhh, a hack

		tabs:InvalidateLayout()

		-- In case there were duplicate filenames
		tabs:InvalidateChildren()

		if set_session then
			gace.OpenSession(set_session)
		end
	else
		MsgN("[G-Ace] Warning: failed to remove nonexistent tab ", id)
	end
end

function gace.tab.GetTabIndex(id)
	-- This is quite inefficient. TODO optimize

	local pnl = gace.tab.GetById(id)
	return table.KeyFromValue(gace.tab.GetPanels(), pnl)
end

function gace.tab.ShowTabOnScroller(id)
	local tab = gace.tab.GetById(id)
	if not tab then return end

	local scroller = gace.tab.GetScroller()

	local midx = tab:GetPos() + tab:GetWide()/2

	-- Check if midx is visible
	local visMin = scroller.OffsetX + 30
	local visMax = scroller.OffsetX + scroller:GetWide() - 30

	-- midx is visible, all gucci
	if midx >= visMin and midx <= visMax then return end

	scroller.OffsetX = midx
	scroller:InvalidateLayout(true)
end

gace.AddHook("OnSessionOpened", "Editor_KeepTabsUpdated", function(id)
	gace.tab.Create(id)
	gace.tab.ShowTabOnScroller(id)
end)

gace.AddHook("OnSessionClosed", "Editor_KeepTabsUpdated", function(id)
	gace.tab.Remove(id)
end)
