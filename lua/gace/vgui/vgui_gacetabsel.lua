
local VGUI_EDITOR_TAB_SEL = {
	Init = function(self)
		self:SetText("")
	end,
	PerformLayout = function(self)
		self:SetWide(self:GetTall()+5)
	end,
	Paint = function(self, w, h)

		w = h -- This is slightly hacky, but we want width to be _drawn_ same as height to make it look like a
			  --  square. The extra 5 px in PerformLayout is to add a small margin to right side

		if self.Hovered then
			surface.SetDrawColor(gace.UIColors.tab_bg_hover)
		else
			surface.SetDrawColor(gace.UIColors.tab_bg)
		end
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(gace.UIColors.tab_bg_active)
		surface.DrawRect(3, 5, w-6, 5)
		surface.DrawRect(3, h-10, w-6, 5)

		surface.SetDrawColor(gace.UIColors.tab_border)
		surface.DrawOutlinedRect(0, 0, w, h)
	end,
	DoClick = function(self)
		local menu = DermaMenu()

		menu:AddOption("Go to file", function()
			gace.ext.ShowTextInputPrompt("File path", function(path)
				local rownum = path:match("@(%d+)$")
				if rownum then path = path:sub(1, -(#rownum+2)) end

				gace.OpenSession(path, {
					callback = function()
						if rownum then
							gace.JSBridge().editor.moveCursorTo(rownum, 0)
							gace.JSBridge().HighlightRow(rownum)
						end
					end
				})
			end)
		end)
		menu:AddSpacer()

		for _,pnl in pairs(gace.tab.GetPanels()) do
			if pnl.SessionId then
				menu:AddOption(pnl.SessionId, function() gace.OpenSession(pnl.SessionId) end)
			end
		end
		menu:Open()
	end,
}

derma.DefineControl( "GAceTabSelector", "Tab selector for GAce", VGUI_EDITOR_TAB_SEL, "DButton" )
