

function gace.ShowEditor()
	if gace.Frame:IsVisible() then return end
	gace.Frame:Show()
end
function gace.HideEditor()
	if not gace.Frame:IsVisible() then return end
	gace.Frame:Hide()
end

function gace.CreateEditor()
	local frame = gace.CreateFrame()
	gace.Frame = frame

	frame.BasePanel = vgui.Create("DDynPanel", frame)
	frame.BasePanel:Dock(FILL)
end
function gace.OpenEditor()
	-- If instance of Frame exists, just show it
	if IsValid(gace.Frame) then
		gace.ShowEditor()
	else
		gace.CreateEditor()
		gace.ShowEditor()
	end
end

concommand.Add("gace-open", gace.OpenEditor)