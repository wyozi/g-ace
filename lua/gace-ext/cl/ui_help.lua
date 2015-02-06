gace.AddHook("AddPanels", "Editor_AddHelpPanel", function(frame, basepnl)
	local sb = basepnl:AddSubPanel("HelpSideBar", RIGHT)
	sb:SetWide(400)

	local pnl = vgui.Create("DPanel")
	pnl:SetPaintBackground(false)

	local docshtml = pnl:Add("DHTML")
	docshtml:Dock(FILL)
	docshtml.Loaded = false

	pnl.SetOpened = function(self, b)
		if self.IsOpened == b then return end

		if b and not docshtml.Loaded then
			docshtml:OpenURL("http://cdn.rawgit.com/wyozi/80200b8bb334113079ef/raw/help.html?vers=0.0.1")
			docshtml.Loaded = true
		end
		self.IsOpened = b

		sb:SetVisible(b)
		basepnl:PerformLayout() -- to make sure there are no "ghost" panels

		if b then
			gace.ext.PushESCListener(function()
				local p = gace.GetPanel("HelpPanel")
				if p.IsOpened then
					p:SetOpened(false)
				else
					return false
				end
			end)
		end

		return b
	end
	pnl:SetOpened(false)

	pnl.HTML = docshtml

	sb:AddDocked("HelpPanel", pnl, FILL)
end)

gace.AddHook("AddActionBarComponents", "ActionBar_HelpCommand", function(comps)
	comps:AddCategory("Help", Color(211, 84, 0), 75)
	comps:AddComponent {
		text = function()
			local docshtml = gace.GetPanel("HelpPanel")
			return docshtml and docshtml.IsOpened and "Close help" or "Help"
		end,
		width = 100,
		fn = function()
			local docshtml = gace.GetPanel("HelpPanel")
			if docshtml then
				docshtml:SetOpened(not docshtml.IsOpened)
			end
		end
	}
	comps:AddCategoryEnd()
end)
