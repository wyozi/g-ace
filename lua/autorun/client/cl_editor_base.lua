

function gace.ShowEditor()
	if gace.Frame:IsVisible() then return end
	gace.Frame:Show()
end
function gace.HideEditor()
	if not gace.Frame:IsVisible() then return end
	gace.Frame:Hide()
end

function gace.AddBasePanels(frame)
	local basepnl = frame.BasePanel

	-- The actual editor
	do
		local html = vgui.Create("DHTML")

		basepnl:AddDocked("Editor", html, FILL)

		html:OpenURL("http://wyozi.github.io/g-ace/editor_refactored.html")
	end

	-- Tabs
	do
		local tabs = gace.CreateTabPanel()
		basepnl:AddDocked("Tabs", tabs, TOP)
	end

end
function gace.CreateEditor()
	local frame = gace.CreateFrame()
	gace.Frame = frame

	frame.BasePanel = vgui.Create("DDynPanel", frame)
	frame.BasePanel:Dock(FILL)

	gace.AddBasePanels(frame)

	gace.CallHook("AddPanels", frame, frame.BasePanel)
end
function gace.OpenEditor()
	-- If instance of Frame exists, just show it
	if IsValid(gace.Frame) then
		gace.ShowEditor()
	else
		gace.CreateEditor()
		gace.Frame:MakePopup()
	end
end

concommand.Add("gace-open", gace.OpenEditor)
concommand.Add("gace-reopen", function()
	if IsValid(gace.Frame) then gace.Frame:Remove() end
	gace.OpenEditor()
end)