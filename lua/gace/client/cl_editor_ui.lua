-- This file contains bunch of helper function to make creating G-Ace UI conforming panels easier

gace.UIColors = gace.UIColors or {
	frame_bg = Color(29,31,33),
	frame_fg = Color(255, 255, 255),

	tab_fg = Color(255, 255, 255),
	tab_bg = Color(78, 77, 74),
	tab_bg_active = Color(52, 73, 94),
	tab_bg_hover = Color(30, 130, 76),

	tab_border = Color(127, 127, 127, 120),

	treenode_bg_active = Color(52, 73, 94),
	treenode_bg_hover = Color(30, 130, 76),
}

-- On light themes things like tab backgrounds look terrible by default
-- We want to use some HSV magic to make them match theme colors
local function MatchThemeColors()
	local frame_bg = gace.UIColors.frame_bg
	local tab_bg = gace.UIColors.tab_bg

	local function HSVMod(clr, h, s, v)
		local _h, _s, _v = ColorToHSV(clr)
		return HSVToColor((_h+h)%360, math.Clamp(_s+s, 0, 1), math.Clamp(_v+v, 0, 1))
	end

	-- Check if frame bg is light
	-- source: http://stackoverflow.com/a/24261119
	local is_light = (1-(0.299*frame_bg.r + 0.587*frame_bg.g + 0.114*frame_bg.b)/255) < 0.5

	gace.UIColors.tab_bg_hover = HSVMod(tab_bg, 0, 0, (is_light and -1 or 1) * 0.25)
	gace.UIColors.tab_bg_active = HSVMod(tab_bg, 0, 0, (is_light and -1 or 1) * 0.2)

	gace.UIColors.treenode_bg_hover = HSVMod(tab_bg, 0, 0, (is_light and -1 or 1) * 0.25)
	gace.UIColors.treenode_bg_active = HSVMod(tab_bg, 0, 0, (is_light and -1 or 1) * 0.2)
end
gace.AddHook("EditorThemeChanged", "Editor_MatchThemeColors", MatchThemeColors)

function gace.GetFrameDimensions()
	local c_x, c_y, c_w, c_h = cookie.GetNumber("gace-frame-x"),
							   cookie.GetNumber("gace-frame-y"),
							   cookie.GetNumber("gace-frame-w"),
							   cookie.GetNumber("gace-frame-h")

	if not c_x then c_x = 0 end
	if not c_y then c_y = 0 end
	if not c_w or c_w <= 0 then c_w = 900 end
	if not c_h or c_h <= 0 then c_h = 600 end

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

function gace.GetPanel(id)
	if not IsValid(gace.Frame) then return end
	return gace.Frame.BasePanel:GetById(id)
end

function gace.ResetDimensions()
	gace.Frame:SetSize(600, 400)
	gace.Frame:Center()
end
concommand.Add("gace-resetdims", gace.ResetDimensions)
