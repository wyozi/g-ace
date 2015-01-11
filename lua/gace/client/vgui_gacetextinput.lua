
local VGUI_GACEINPUT = {
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

		local fg = self:QueryColor("tab_fg")
		if self:GetDisabled() then
			fg = Color(150, 150, 150)
		end

		surface.SetDrawColor(fg.r, fg.g, fg.b, 90)
		surface.DrawRect(0, 0, w, h)

		if self:GetDisabled() then
			surface.SetDrawColor(127, 110, 110)
		else
			surface.SetDrawColor(self:QueryColor("tab_bg"))
		end
		surface.DrawRect(1, 1, w-2, h-2)

		local textcolor = fg

		self:DrawTextEntryText(textcolor, self.m_colHighlight, textcolor)
		return true
	end,
}

derma.DefineControl( "GAceInput", "Text input for GAce", VGUI_GACEINPUT, "DTextEntry" )