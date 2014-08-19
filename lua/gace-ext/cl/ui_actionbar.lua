
local comp_meta = {
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
	for _,v in pairs(comps) do
		local is_label = not v.fn

		local comp = vgui.Create(is_label and "DLabel" or "GAceButton", frame)
		comp:SetPos(x, 2)
		comp:SetSize(v.width or 60, 20)
		x = x + (v.width or 60)+2
		comp:SetText(v.text)

		if v.toggle then comp.ToggleMode = true end

		if is_label then
			comp.Think = function(self) self:SetColor(gace.UIColors.frame_fg) end
		end

		if v.tt then comp:SetToolTip(v.tt) end

		if v.enabled and not v.enabled() then
			comp.Think = function(self)
				local b = v.enabled()
				-- Yes, this inverses enabled to disabled, blame Garry for weird naming
				self:SetDisabled(not b)
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