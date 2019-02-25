-- The code here is bad and you should probably not read it.

local comp_meta = {
	AddCategory = function(self, title, clr, width)
		table.insert(self, {text = title, width = (width) or (#title*15), iscat = true, color = clr or Color(255, 127, 0), toggle = true})
	end,
	AddCategoryEnd = function(self)
		table.insert(self, {iscat = true, nullcat = true})
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

	local horiz_scroller = vgui.Create("DHorizontalScroller", frame)
	local opl = horiz_scroller.PerformLayout
	horiz_scroller.PerformLayout = function(self)
		self:SetPos(30, 0)

		local max_width = frame:GetWide() - 100 - 30

		-- Compute horizscroller width
		local w = 0
		for i=1, #self.Panels do
			w = w + self.Panels[i]:GetWide() - self.m_iOverlap
		end
		self:SetSize(math.min(w, max_width), 24)

		return opl(self)
	end

	-- For some STUPID reason frame resize doesn't trigger PerformLayout, so we
	-- have to do this crap manually
	local last_framew
	horiz_scroller.Think = function(self)
		if IsValid(frame) then
			local framew = frame:GetWide()
			if last_framew and last_framew ~= framew then
				self:InvalidateLayout()
			end
			last_framew = framew
		end
	end

	horiz_scroller:SetOverlap(-2)

	local cur_cat

	local function AddCategory(v)
		if v.nullcat then
			cur_cat = nil
			return
		end
		cur_cat = v
	end

	local function AddComp(v)
		if v.iscat == true then
			AddCategory(v)
			return
		end

		local isSplitButton = not not v.splitFn

		local comp = vgui.Create(isSplitButton and "GAceSplitButton" or "GAceButton", actbar_wrapper)
		comp:SetSize(v.width or 60, 24)
		comp:SetColorOverride("tab_bg", v.color or (cur_cat and cur_cat.color))
		comp:SetColorOverride("tab_fg", Color(255, 255, 255))

		comp.Think = function(self)
			if v.enabled then
				local b = v.enabled()
				-- Yes, this inverses enabled to disabled, blame Garry for weird naming
				self:SetDisabled(not b)
			end

			self:SetText(type(v.text) == "function" and v.text() or v.text)
		end

		if v.fn then
			comp.DoClick = function(self)
				if not self:GetDisabled() then
					v.fn(self, self.Toggled)
				end
			end
		end
		if v.splitFn then
			comp.DoRightClick = function(self)
				local menu = DermaMenu()
				v.splitFn(menu)
				menu:Open()
				menu:SetPos(comp:LocalToScreen(0, comp:GetTall()))
			end
		end

		horiz_scroller:AddPanel(comp)
	end

	for _,v in pairs(comps) do
		AddComp(v)
	end
end)
