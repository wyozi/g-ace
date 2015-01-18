
surface.CreateFont("EditorTabFont", {
	font = "Roboto",
	size = 14
})

local max = 14
local thickness = 2
local cross_poly1 = {
    { x = 0, y = 0 },
    { x = thickness, y = 0 },
    { x = max, y = max-thickness },
    { x = max, y = max },
    { x = max-thickness, y = max },
    { x = 0, y = thickness }
}

local cross_poly2 = {
    { x = max, y = 0 },
    { x = max, y = thickness },
    { x = thickness, y = max },
    { x = 0, y = max },
    { x = 0, y = max-thickness },
    { x = max-thickness, y = 0 },
}

local cross_matrix = Matrix()
-- close button size can't change so this is fine
cross_matrix:SetTranslation(Vector(24/2 - 7, 22/2 - 7, 0))

local VGUI_EDITOR_TAB = {
	Init = function(self)
		self.CloseButton = vgui.Create("DButton", self)
		self.CloseButton:SetText("")
		self.CloseButton.Paint = function(pself, w, h)
			surface.SetDrawColor(150, 40, 27)
			if pself.Hovered then surface.SetDrawColor(242, 38, 19) end
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(189, 195, 199)
			draw.NoTexture()

			cam.PushModelMatrix(cross_matrix)
				surface.DrawPoly(cross_poly1)
				surface.DrawPoly(cross_poly2)
			cam.PopModelMatrix()
		end
		--self.CloseButton:SetIcon("icon16/cancel.png")
		self.CloseButton.DoClick = function()
			self:CloseTab()
		end
	end,
	CloseTab = function(self, force, callback)
		local sess = gace.GetSession(self.SessionId)
		if not force and not sess:IsSaved() then
			local menu = DermaMenu()
			menu:AddOption("Unsaved changes. Are you sure you want to close the tab?", function()
				self:CloseTab(true, callback)
			end):SetIcon("icon16/stop.png")

			local x, y = self:GetPos()
			local x2, y2 = gace.Frame:GetPos()
			local w, h = self:GetSize()
			x, y = x2 + x + w, y2 + y + h

			menu:Open()
			menu:SetPos(x, y)
			return
		end

		gace.CloseSession(self.SessionId)
		if callback then callback() end
	end,
	PerformLayout = function(self)
		self.CloseButton:SetPos(self:GetWide() - self:GetTall() - 1, 1)
		self.CloseButton:SetSize(self:GetTall(), self:GetTall() - 2)

		surface.SetFont("EditorTabFont")
		local w = surface.GetTextSize(self.FileName) + (self.TextLeftPadding or 0) + 35 --[[close btn]]
		self:SetWide(math.max(w, 120))
	end,
	Paint = function(self, w, h)
		gace.CallHook("PreDrawTab", self, self.SessionId)

		if self.Hovered then
			surface.SetDrawColor(gace.UIColors.tab_bg_hover)--52, 152, 219)
		elseif self.SessionId == gace.GetSessionId() then
			surface.SetDrawColor(gace.UIColors.tab_bg_active)--44, 62, 80)
		else
			surface.SetDrawColor(gace.UIColors.tab_bg)--127, 140, 141)
		end
		surface.DrawRect(0, 0, w, h)

		draw.SimpleText(self.FileName, "EditorTabFont", 5 + (self.TextLeftPadding or 0), h/2, gace.UIColors.tab_fg, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local sess = gace.GetSession(self.SessionId)
		if sess and not sess:IsSaved() then
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

		local hh, s, v = ColorToHSV(gace.UIColors.frame_bg)
		surface.SetDrawColor(HSVToColor(hh, s, v-0.1))
		surface.DrawOutlinedRect(0, 0, w, h)

		gace.CallHook("PostDrawTab", self, self.SessionId)
	end,
	Setup = function(self, id)
		self:SetText("")
		self.SessionId = id
		self:SetToolTip(id)

		self.FileName = gace.Path(self.SessionId):GetFile()

		surface.SetFont("EditorTabFont")
		local w = surface.GetTextSize(self.SessionId)
	end,
	DoClick = function(self)
		gace.OpenSession(self.SessionId)
	end,
	DoRightClick = function(self)

		-- Timer simples here are because opening another menu from menu isn't possible. There needs to be a slight delay

		local menu = DermaMenu()
		menu:AddOption("Close", function() timer.Simple(0, function() self:CloseTab() end) end)
		menu:AddOption("Close others", function()
			local tabs = gace.GetPanel("Tabs")
			local to_be_closed = gace.FilterSeq(tabs.Panels, function(x) return x.SessionId ~= nil and x ~= self end)

			local function CloseAnother()
				local tab = table.remove(to_be_closed, 1)
				if not tab then return end

				-- Delay slightly longer here because the tab HorizontalScroller needs to update so DMenu
				-- pops up at the right place
				tab:CloseTab(nil, function() timer.Simple(0.1, CloseAnother) end)
			end

			timer.Simple(0, CloseAnother)
		end)
		menu:Open()
	end,
}

derma.DefineControl( "GAceTab", "Tab for GAce", VGUI_EDITOR_TAB, "DButton" )
