
-- Obsolete. Replaced by my new knowledge of DHorizontalDivider existing. Not deleted because there might be use
-- for this some time

local VGUI_SPLITTER = {
	Init = function(self)
		self:SetDrawBackground(false)

		self.Panels = {}
		self.PanelShare = {}

		self.IsVertical = false
	end,
	SetPanel = function(self, index, panel, share)
		share = share or 1

		panel:SetParent(self)

		self.Panels[index] = panel
		self.PanelShare[index] = share
	end,
	PerformLayout = function(self)
		local total_share = 0
		local total_dim = self:GetWide()

		for i,v in pairs(self.Panels) do
			total_share = total_share + self.PanelShare[i]
		end

		local x = 0
		for i,v in pairs(self.Panels) do
			local frac_share = self.PanelShare[i] / total_share

			local width = frac_share * total_dim

			v:SetPos(x, 0)
			v:SetSize(width, self:GetTall())

			x = x + width
		end

	end,
}

derma.DefineControl( "GAceSplitter", "Splitter for GAce", VGUI_SPLITTER, "DPanel" )