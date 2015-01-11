
local VGUI_BUTTON = {
	QueryColor = function(self, clrid)
		local colors = self.Colors
		local clr = colors and colors[clrid]
		return clr or gace.UIColors[clrid]
	end,
	SetColorOverride = function(self, clrid, clr)
		self.Colors = self.Colors or {}
		self.Colors[clrid] = clr
	end,
	Paint = function(self, w, h)
		local colors = self.Colors
		if self:GetDisabled() then
			surface.SetDrawColor(127, 110, 110)
		elseif self.Depressed then
			surface.SetDrawColor(self:QueryColor("tab_bg_active"))
		elseif self.Hovered then
			surface.SetDrawColor(self:QueryColor("tab_bg_hover"))
		elseif self.ToggleMode and self.Toggled then
			surface.SetDrawColor(self:QueryColor("tab_bg_active"))
		else
			surface.SetDrawColor(self:QueryColor("tab_bg"))
		end
		surface.DrawRect(0, 0, w, h)

		local fg = self:QueryColor("tab_fg")
		if self:GetDisabled() then
			fg = Color(150, 150, 150)
		end

		draw.SimpleText(self:GetText(), "EditorTabFont", w/2, h/2, fg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
		return true
	end,
}

derma.DefineControl( "GAceButton", "Button for GAce", VGUI_BUTTON, "DButton" )