
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
			surface.SetDrawColor(34, 36, 37)
			--surface.SetDrawColor(self:QueryColor("tab_bg"))
		end
		surface.DrawRect(1, 1, w-2, h-2)

		local textcolor = fg
		self:DrawText(textcolor)

		return true
	end,

	DrawText = function(self, textcolor)
		self:DrawTextEntryText(textcolor, Color(255, 127, 0), textcolor)
	end,

	-- Enabling history requires some hacks, so we'll have a method for that
	EnableHistory = function(self)
		self:SetHistoryEnabled(true)

		-- Override OnKeyCodeTyped
		-- Requires some bloat code from dtextentry.lua
		self.OnKeyCodeTyped = function(self, code)
			if self:OnKeyCode(code) then return end

			if code == KEY_ENTER and not self:IsMultiline() and self:GetEnterAllowed() then
				if IsValid(self.Menu) then
					self.Menu:Remove()
				end

				self:AddHistory(self:GetText())

				self:FocusNext()
				self:OnEnter()
				self.HistoryPos = 0

				self:OnTextChanged()
			end

			if self.m_bHistory or IsValid(self.Menu) then
				if code == KEY_UP then
					self.HistoryPos = self.HistoryPos - 1;
					self:UpdateFromHistory()
				end

				if code == KEY_DOWN then
					self.HistoryPos = self.HistoryPos + 1;
					self:UpdateFromHistory()
				end
			end
		end

		self.OnLoseFocus = function(self)
			hook.Call("OnTextEntryLoseFocus", nil, self)
		end
	end
}

derma.DefineControl( "GAceInput", "Text input for GAce", VGUI_GACEINPUT, "DTextEntry" )
