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

	-- This is also known as a huge hack.
	-- To make it possible to dynamically collapse/expand action bar elements, the x position delta (from prev element) is stored
	-- for every single element in the following table. The runtime x can then be computed by summing all previous values together
	local x_off_cache = {}

	local function GetXPosFor(element)
		local x = 0
		for i=1,#x_off_cache do
			if x_off_cache[i].el == element then return x end
			if not x_off_cache[i].hidden or x_off_cache[i].el.iscat then
				x = x + x_off_cache[i].off
			end
		end
		return x
	end

	-- if vis == nil, toggle
	local function SetCatVisibility(cat, vis)
		local v

		for i=1,#x_off_cache do
			if x_off_cache[i].el.cat == cat then
				if vis == nil then
					x_off_cache[i].hidden = not x_off_cache[i].hidden
					v = not x_off_cache[i].hidden
				else
					x_off_cache[i].hidden = not vis
				end
			end
		end

		return v
	end
	local function IsInvis(el)
		if el.iscat then return false end

		for i=1,#x_off_cache do
			if x_off_cache[i].el == el then return x_off_cache[i].hidden end
		end
	end

	local ab_catvis = gace.ClientCache:get("actionbar_catvis")

	local cur_cat

	for _,v in pairs(comps) do
		local is_cat = v.iscat == true
		if is_cat then
			-- comp containing nullcat is a meta component to end a category
			if v.nullcat then
				cur_cat = nil
				table.insert(x_off_cache, {el=v, off=6})

				continue
			end
			cur_cat = v
		end

		local is_label = not v.fn and not is_cat

		local width = (v.width or 60)

		v.cat = cur_cat

		if cur_cat then
			local comp = vgui.Create("DPanel", frame)
			comp:SetDrawBackground(false)

			local curcatclr = cur_cat.color
			comp.Paint = function(s, w, h)
				if IsInvis(v) then return end
				surface.SetDrawColor(curcatclr.r, curcatclr.g, curcatclr.b, 160)
				surface.DrawRect(0, 0, w, h)
			end
			comp.Think = function(s)
				s:SetPos(GetXPosFor(v), 0)
			end
			comp:SetSize(width+4, 24)
		end

		local comp = vgui.Create(is_label and "DLabel" or "GAceButton", frame)
		if is_cat then
			comp:SetSize(width, 24)
			comp:SetColorOverride("tab_bg", v.color)

			v.fn = function()
				local set_to = SetCatVisibility(v.cat)

				-- We don't wanna persist functions..
				if type(v.text) == "string" then
					local cache = gace.ClientCache:getDynTable("actionbar_catvis", true)
					cache[v.text] = set_to
				end
			end
		else
			comp:SetSize(width, 20)
		end

		local is_visible = true

		if is_cat and ab_catvis and ab_catvis[v.text] ~= nil then
			is_visible = tobool(ab_catvis[v.text])
		end

		table.insert(x_off_cache, {el=v, off=width+2, hidden = not is_visible})

		if v.text then
			comp:SetText(type(v.text) == "function" and v.text() or v.text)
		end

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

			local is_visible = not IsInvis(v)

			comp:SetPos(is_visible and GetXPosFor(v) or -1000, is_cat and 0 or 2)
		end

		if v.fn then
			comp.DoClick = function(self)
				if not self:GetDisabled() then
					v.fn(self, self.Toggled)
				end
			end
		end
	end

	-- Some categories mightve been hidden already in above code, so we need to
	-- loop through all cats and see if theyre hidden
	for i=1,#x_off_cache do
		if x_off_cache[i].el.iscat and x_off_cache[i].hidden then
			SetCatVisibility(x_off_cache[i].el, false)
		end
	end
end)
