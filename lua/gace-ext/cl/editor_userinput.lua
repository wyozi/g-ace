gace.AddHook("AddPanels", "Editor_AddUserInput", function(frame, basepnl)
	local inputpanel = vgui.Create("DPanel", frame)
	inputpanel:Dock(BOTTOM)
	inputpanel:Hide()

	do
		local input = vgui.Create("DTextEntry", inputpanel)
		input:Dock(FILL)
		inputpanel.Input = input

		input.PaintOver = function(self, w, h)
			if self:GetText() == "" then
				draw.SimpleText(inputpanel.QueryString or "bla bla bla", "DermaDefault", 4, h/2, Color(0, 0, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end

		input.OnEnter = function(self)
			inputpanel.InputCallback(self:GetText())
			inputpanel:Hide()
			gace.Frame:InvalidateLayout()
		end
	end

	basepnl:AddDocked("InputPanel", inputpanel, BOTTOM)
end)

function gace.ext.ShowTextInputPrompt(query, callback)
	local inputpanel = gace.GetPanel("InputPanel")

	inputpanel.InputCallback = callback
	inputpanel.QueryString = query or ""

	inputpanel.Input:SetText(default or "")
	inputpanel.Input:RequestFocus()

	inputpanel:Show()
end