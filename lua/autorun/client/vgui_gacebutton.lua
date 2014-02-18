
local VGUI_BUTTON = {
	Paint = function(self, w, h)
		if self:GetDisabled() then
			surface.SetDrawColor(127, 110, 110)
		elseif self.Depressed then
			surface.SetDrawColor(gace.UIColors.tab_bg_active)
		elseif self.Hovered then
			surface.SetDrawColor(gace.UIColors.tab_bg_hover)
		else
			surface.SetDrawColor(gace.UIColors.tab_bg)
		end
		surface.DrawRect(0, 0, w, h)

		draw.SimpleText(self:GetText(), "EditorTabFont", w/2, h/2, self:GetDisabled() and 
			Color(150, 150, 150) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
		return true
	end,
}

derma.DefineControl( "GAceButton", "Button for GAce", VGUI_BUTTON, "DButton" )