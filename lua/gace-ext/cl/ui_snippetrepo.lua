if true then return end

local base_url = "https://obscure-waters-1458.herokuapp.com/"

gace.AddHook("AddActionBarComponents", "ActionBar_SnippetCommand", function(comps)
	comps:AddCategory("Snippet", Color(51, 110, 123), 75)
	comps:AddComponent {
		text = "Snippet repo",
		width = 100,
		fn = function(comp)
			local pnl = vgui.Create("DPanel", gace.Frame)

			-- There is no simple way to get position of Snippet button relative
			-- to the G-Ace frame, so we use a small hack
			local f_absX, f_absY = gace.Frame:LocalToScreen(0, 0)
			local btn_absX, btn_absY = comp:LocalToScreen(0, 0)
			local x, y = btn_absX - f_absX, btn_absY - f_absY

			pnl:SetPos(x, y)

			local search = vgui.Create("GAceInput", pnl)
			search:SetWide(275)
			search:Dock(TOP)

			search.PaintOver = function(pself, w, h)
				if not pself.Loading then return end

				local midx, midy = w-25, h/2
				local radius = 6

				local t = CurTime()*5

				for i=0, 8 do
					surface.SetDrawColor(HSVToColor(t/50 + i*50, 0.9, 0.5))
					surface.DrawRect(midx + math.cos(t + i/4)*radius - 2, midy + math.sin(t + i)*radius - 2, 3, 3)
				end
			end

			local results = vgui.Create("DPanel", pnl)
			results.PerformLayout = function(pself)
				local h = 0
				for i,c in pairs(pself:GetChildren()) do
					c:SetPos(0, (i-1)*50)
					c:SetSize(275, 50)
					h = h + 50
				end

				pself:SizeToContents()
				pself:InvalidateParent()
			end
			results:Dock(FILL)

			local function ClearResults(close_all)
				results:Clear()
				results:InvalidateLayout(true)

				if close_all then
					pnl:Remove()
				end
			end

			pnl.PerformLayout = function(pself)
				pself:SetSize(275, search:GetTall() + math.min(#results:GetChildren()*50, 250))
			end
			search:RequestFocus()

			search.OnChange = function(pself)
				local txt = pself:GetText()

				if txt:Trim() == "" then
					ClearResults()
					timer.Destroy("gace-snippetsearch")
					return
				end

				timer.Create("gace-snippetsearch", 0.5, 1, function()
					search.Loading = true

					http.Fetch(base_url .. "snippets?query=" .. txt, function(raw)
						local data = util.JSONToTable(raw)
						ClearResults()

						for _,res in pairs(data) do
							local respnl = vgui.Create("GAceSnippetButton")
							respnl:SetSize(275, 60)

							respnl.Title = res.title
							respnl.Desc = res.desc

							respnl.DoClick = function()
								ClearResults(true)

								http.Fetch(base_url .. "snippets/" .. res.id, function(raw)
									local data = util.JSONToTable(raw)
									gace.JSBridge().insertSnippet(data.code)
								end)
							end

							results:Add(respnl)
						end

						results:InvalidateLayout(true)

						search.Loading = false
					end)
				end)
			end

			gace.ext.PushESCListener(function()
				if IsValid(pnl) then
					pnl:Remove()
				else
					return false
				end
			end)
		end
	}
	comps:AddCategoryEnd()
end)

surface.CreateFont("GAceSnippetTitle", {
	font = "Roboto",
	size = 22
})
surface.CreateFont("GAceSnippetDesc", {
	font = "Roboto",
	size = 15,
	italic = true
})

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

		draw.SimpleText(self.Title, "GAceSnippetTitle", 5, 5, fg)
		draw.SimpleText(self.Desc, "GAceSnippetDesc", 5, h-5, ColorAlpha(fg, 120), _, TEXT_ALIGN_TOP)

		return true
	end,
}

derma.DefineControl( "GAceSnippetButton", "SnippetButton for GAce", VGUI_BUTTON, "DButton" )
