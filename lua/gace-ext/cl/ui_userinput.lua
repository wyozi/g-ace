gace.AddHook("AddPanels", "Editor_AddUserInput", function(frame, basepnl)
	local inputpanel = vgui.Create("DPanel")
	inputpanel:Hide()

	do
		local input = vgui.Create("GAceInput", inputpanel)
		input:Dock(FILL)
		inputpanel.Input = input

		input.PaintOver = function(self, w, h)
			if self:GetText() == "" then
				local fgcolor = gace.UIColors["tab_fg"]
				draw.SimpleText(inputpanel.QueryString or "bla bla bla", "DermaDefault", 4, h/2, Color(fgcolor.r, fgcolor.g, fgcolor.b, 127), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end

		input.OnEnter = function(self)
			inputpanel.InputCallback(self:GetText())
			inputpanel:Hide()
			gace.Frame.BasePanel:InvalidateLayout(true)
		end
	end

	basepnl:AddDocked("InputPanel", inputpanel, BOTTOM)
end)

function gace.ext.ShowTextInputPrompt(query, callback, default)
	local inputpanel = gace.GetPanel("InputPanel")

	inputpanel.InputCallback = callback
	inputpanel.QueryString = query or ""

	inputpanel.Input:SetText(default or "")
	inputpanel.Input:RequestFocus()

	inputpanel:Show()
end

function gace.ext.ShowYesNoCancelPrompt(query, callback)
	local function curry(str) return function() callback(str) end end
	Derma_Query(query, "Confirmation", "Yes", curry("yes"), "No", curry("no"), "Cancel", curry("cancel"))
end

function gace.ext.ShowYesCancelPrompt(query, callback)
	local function curry(str) return function() callback(str) end end
	Derma_Query(query, "Confirmation", "Yes", curry("yes"), "Cancel", curry("cancel"))
end
