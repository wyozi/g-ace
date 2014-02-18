
local VGUI_EDITOR_TAB = {
	Init = function(self)
		self.CloseButton = vgui.Create("DImageButton", self)
		self.CloseButton:SetIcon("icon16/cancel.png")
		self.CloseButton.DoClick = function()
			self:CloseTab()
		end
	end,
	CloseTab = function(self, force)
		if not force and self.EditedNotSaved then
			local menu = DermaMenu()
			menu:AddOption("Unsaved changes. Are you sure you want to close the tab?", function()
				self:CloseTab(true)
			end):SetIcon("icon16/stop.png")
			menu:Open()
			return
		end

		local prev_tab = table.FindPrev(gace.Tabs.Panels, self)
		local set_session
		if prev_tab and prev_tab.SessionId then
			set_session = prev_tab.SessionId
		end

		gace.CloseSession(self.SessionId)
		self:Remove()
		table.RemoveByValue(gace.Tabs.Panels, self) -- uhh
		gace.Tabs:InvalidateLayout()

		if set_session then
			gace.ReOpenSession(set_session)
		end
	end,
	PerformLayout = function(self)
		self.CloseButton:SetPos(self:GetWide() - 18, self:GetTall()/2-16/2)
		self.CloseButton:SetSize(16, 16)
	end,
	Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(gace.UIColors.tab_bg_hover)--52, 152, 219)
		elseif self.SessionId == gace.OpenedSessionId then
			surface.SetDrawColor(gace.UIColors.tab_bg_active)--44, 62, 80)
		else
			surface.SetDrawColor(gace.UIColors.tab_bg)--127, 140, 141)
		end
		surface.DrawRect(0, 0, w, h)

		draw.SimpleText(self.SessionId, "EditorTabFont", w-22, h/2, gace.UIColors.tab_fg, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	
		if self.EditedNotSaved then
			surface.SetDrawColor(HSVToColor(CurTime()*3, 0.5, 0.95))
			local lx, ly
			for x=0,w,5 do
				local y = h-2-math.sin(CurTime()*2+x)*2
				if lx then
					surface.DrawLine(lx, ly, x, y)
				end
				lx, ly = x, y
			end
		end

	end,
	Setup = function(self, id)
		self:SetText("")
		self.SessionId = id
		self:SetToolTip(id)

		surface.SetFont("EditorTabFont")
		local w = surface.GetTextSize(self.SessionId)

		self:SetWide(140)--math.min(w+34, 160))
	end,
	DoClick = function(self)
		gace.ReOpenSession(self.SessionId)
	end,
	DoRightClick = function(self)
		local menu = DermaMenu()
		menu:AddOption("Close", function() self:CloseTab() end)
		menu:Open()
	end,
}

derma.DefineControl( "GAceTab", "Tab for GAce", VGUI_EDITOR_TAB, "DButton" )