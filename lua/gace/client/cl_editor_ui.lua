-- This file contains bunch of helper function to make creating G-Ace UI conforming panels easier

gace.UIColors = {
	frame_bg = Color(29,31,33),
	frame_fg = Color(255, 255, 255),

	tab_fg = Color(255, 255, 255),
	tab_bg = Color(78, 77, 74),
	tab_bg_hover = Color(148, 186, 101),
	tab_bg_active = Color(39, 144, 176),

	treenode_bg_hover = Color(128, 166, 81),
	treenode_bg_active = Color(29, 104, 126),
}

function gace.GetFrameDimensions()
	local c_x, c_y, c_w, c_h = cookie.GetNumber("gace-frame-x"),
							   cookie.GetNumber("gace-frame-y"),
							   cookie.GetNumber("gace-frame-w"),
							   cookie.GetNumber("gace-frame-h")

	if c_w == 0 then c_w = 900 end
	if c_h == 0 then c_h = 600 end

	return c_x, c_y, c_w, c_h
end

function gace.StoreFrameDimensions(frame)
	local x, y = frame:GetPos()
	local w, h = frame:GetSize()

	cookie.Set("gace-frame-x", x)
	cookie.Set("gace-frame-y", y)
	cookie.Set("gace-frame-w", w)
	cookie.Set("gace-frame-h", h)
end

function gace.CreateFrame()
	local frame = vgui.Create("DFrame")
	frame:SetDeleteOnClose(false)
	frame:SetSizable(true)
	frame:SetTitle("")
	frame.OnClose = function()
		gace.CallHook("FrameClosed", frame)
	end
	frame.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.frame_bg)
		surface.DrawRect(0, 0, w, h)

		gace.CallHook("PostFramePainted", self, w, h)
	end

	local oldthink = frame.Think
	frame.Think = function(self)
		gace.CallHook("FrameThink", self)

		oldthink(self)
	end

	local c_x, c_y, c_w, c_h = gace.GetFrameDimensions()

	frame:SetSize(c_w, c_h)
	if c_x == 0 and c_y == 0 then
		frame:Center()
	else
		frame:SetPos(c_x, c_y)
	end

	-- A timer that automatically updates GAce dimensions stored in cookies
	timer.Create("gace-frame-cookies", 1, 0, function()
		if not IsValid(frame) then return end
		gace.StoreFrameDimensions(frame)
	end)

	return frame
end

function gace.CreateTabPanel()
	local tabs = vgui.Create("DHorizontalScroller")
	tabs.Paint = function(self, w, h)
		local hh, s, v = ColorToHSV(gace.UIColors.frame_bg)
		surface.SetDrawColor(HSVToColor(hh, s, v-0.1))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	tabs:SetOverlap(-1)

	local tabsel = vgui.Create("GAceTabSelector", tabs)
	tabs:AddPanel(tabsel)

	return tabs
end

function gace.GetPanel(id)
	if not IsValid(gace.Frame) then return end
	return gace.Frame.BasePanel:GetById(id)
end

function gace.ResetDimensions()
	gace.Frame:SetSize(600, 400)
	gace.Frame:Center()
end
concommand.Add("gace-resetdims", gace.ResetDimensions)
