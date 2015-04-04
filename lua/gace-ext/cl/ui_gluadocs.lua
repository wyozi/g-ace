gace.AddHook("AddPanels", "Editor_AddDocsSideBar", function(frame, basepnl)
	local sb = basepnl:AddSubPanel("DocsSideBar", RIGHT)
	sb:SetWide(275)

	local pnl = vgui.Create("DPanel")
	pnl:SetPaintBackground(false)

	local docshtml = pnl:Add("DHTML")
	docshtml:Dock(FILL)
	docshtml.Loaded = false

	docshtml:AddFunction("gace", "OpenUrl", function(url)
		gui.OpenURL(url);
	end)

	pnl.SetOpened = function(self, b)
		if self.IsOpened == b then return end

		if b and not docshtml.Loaded then
			docshtml:OpenURL("http://samuelmaddock.github.io/glua-docs/")
			docshtml.Loaded = true

			docshtml:QueueJavascript([[
				document.body.onclick = function(e) {
					var targ = e.target;
					if (targ.tagName == "A") {
						gace.OpenUrl(targ.getAttribute("href"));
						e.stopPropagation();
					}
					
				}
			]])
		end
		self.IsOpened = b

		sb:SetVisible(b)
		basepnl:PerformLayout() -- to make sure there are no "ghost" panels

		if b then
			gace.ext.PushESCListener(function()
				local p = gace.GetPanel("DocsHTMLPanel")
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

	sb:AddDocked("DocsHTMLPanel", pnl, FILL)
end)

gace.AddHook("SetupHTMLPanel", "SetupGLuaDocsFuncs", function(html)
	html:AddFunction("gace", "OpenDocumentationFor", function(str)
		gace.ext.OpenDocumentationFor(str)
	end)
end)

gace.AddHook("AddActionBarComponents", "ActionBar_GLuaDocsCommand", function(comps)
	comps:AddCategory("Documentation", Color(52, 73, 94), 100)
	comps:AddComponent {
		text = function()
			local docshtml = gace.GetPanel("DocsHTMLPanel")
			return docshtml and docshtml.IsOpened and "Close docs" or "Documentation"
		end,
		width = 100,
		fn = function()
			local docshtml = gace.GetPanel("DocsHTMLPanel")
			if docshtml then
				docshtml:SetOpened(not docshtml.IsOpened)
			end
		end
	}
	comps:AddCategoryEnd()
end)

function gace.ext.OpenDocumentationFor(str)
	local docshtml = gace.GetPanel("DocsHTMLPanel")
	if docshtml then
		docshtml:SetOpened(true)

		-- TODO jsencode?
		docshtml.HTML:QueueJavascript([[
			var el = document.querySelector("input[type='search']");
			el=angular.element(el);

			el.val("]] .. str .. [[");
			el.triggerHandler("change");
		]])
	end
end
