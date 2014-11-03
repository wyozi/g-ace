gace.AddHook("AddPanels", "Editor_AddDocsSideBar", function(frame, basepnl)
	local sb = basepnl:AddSubPanel("DocsSideBar", RIGHT)
	sb:SetWide(275)

	local pnl = vgui.Create("DPanel")
	pnl:SetPaintBackground(false)

	local docshtml = pnl:Add("DHTML")
	docshtml:Dock(FILL)
	docshtml.Loaded = false

	pnl.SetOpened = function(self, b)
		if b and not docshtml.Loaded then
			docshtml:OpenURL("http://samuelmaddock.github.io/glua-docs/")
			docshtml.Loaded = true
		end
		self.IsOpened = b

		sb:SetVisible(b)
		basepnl:PerformLayout() -- to make sure there are no "ghost" panels

		return b
	end
	pnl:SetOpened(false)

	sb:AddDocked("DocsHTMLPanel", pnl, FILL)
end)

gace.AddHook("AddActionBarComponents", "ActionBar_GLuaDocsCommand", function(comps)
	comps:AddCategory("Documentation", Color(52, 73, 94), 100)
	comps:AddComponent {
		text = function()
			local docshtml = gace.GetPanel("DocsHTMLPanel")
			return docshtml and docshtml.IsOpened and "Close" or "Open"
		end,
		width = 70,
		fn = function()
			local docshtml = gace.GetPanel("DocsHTMLPanel")
			if docshtml then
				docshtml:SetOpened(not docshtml.IsOpened)
			end
		end
	}
	comps:AddCategoryEnd()
end)