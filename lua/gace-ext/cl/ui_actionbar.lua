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
		self:SetPos(0, 0)
		self:SetSize(frame:GetWide() - 100, 24)

		return opl(self)
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

		local comp = vgui.Create("GAceButton", actbar_wrapper)
		comp:SetSize(v.width or 60, 24)
		comp:SetColorOverride("tab_bg", v.color or (cur_cat and cur_cat.color))

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

		horiz_scroller:AddPanel(comp)
	end

	for _,v in pairs(comps) do
		AddComp(v)
	end
end)
