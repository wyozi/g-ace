
local comp_meta = {
	AddCategory = function(self, title, clr)
		table.insert(self, {text = title, width = #title*15, cat = true, color = clr or Color(255, 127, 0), toggle = true})
	end,
	AddCategoryEnd = function(self)
		table.insert(self, {cat = true, nullcat = true})
	end,
	AddComponent = function(self, data)
		table.insert(self, data)
	end
}
comp_meta.__index = comp_meta

gace.AddHook("AddPanels", "Editor_AddActionBarButtons", function(frame, basepnl)
	local comps = {}
	setmetatable(comps, comp_meta)

	gace.CallHook("AddActionBarComponents", comps)

	local x = 10
	local cur_cat

	for _,v in pairs(comps) do
		local is_cat = v.cat == true
		if is_cat then
			-- comp containing nullcat is a meta component to end a category
			if v.nullcat then
				cur_cat = nil
				x = x + 6
				continue
			end
			cur_cat = v
		end

		local is_label = not v.fn and not is_cat

		local width = (v.width or 60)

		if cur_cat then
			local comp = vgui.Create("DPanel", frame)
			local curcatclr = cur_cat.color
			comp.Paint = function(s, w, h)
				surface.SetDrawColor(curcatclr.r, curcatclr.g, curcatclr.b, 80)
				surface.DrawRect(0, 0, w, h)
			end
			comp:SetPos(x-2, 0)
			comp:SetSize(width+4, 24)
		end

		local comp = vgui.Create(is_label and "DLabel" or "GAceButton", frame)
		if is_cat then
			comp:SetPos(x, 0)
			comp:SetSize(width, 24)

			comp:SetColorOverride("tab_bg", v.color)
		else
			comp:SetPos(x, 2)
			comp:SetSize(width, 20)
		end
		x = x + width+2

		comp:SetText(type(v.text) == "function" and v.text() or v.text)

		if v.toggle then comp.ToggleMode = true end

		if is_label then
			comp.Think = function(self) self:SetColor(gace.UIColors.frame_fg) end
		end

		if v.tt then comp:SetToolTip(v.tt) end

		comp.Think = function(self)
			if v.enabled then
				local b = v.enabled()
				-- Yes, this inverses enabled to disabled, blame Garry for weird naming
				self:SetDisabled(not b)
			end
			if type(v.text) == "function" then
				self:SetText(v.text())
			end
		end

		if v.fn then
			comp.DoClick = function(self)
				if not self:GetDisabled() then
					if self.ToggleMode then
						self.Toggled = not self.Toggled
					end
					v.fn(self, self.Toggled)
				end
			end
		end
	end
end)