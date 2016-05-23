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
			local t = self:GetText()

			inputpanel:Hide()
			gace.Frame.BasePanel:InvalidateLayout(true)

			inputpanel.InputCallback(self:GetText())
		end
	end

	basepnl:AddDocked("InputPanel", inputpanel, BOTTOM)
end)

function gace.ext.ShowTextInputPrompt(query, callback, default)
	local inputpanel = gace.GetPanel("InputPanel")

	inputpanel.QueryString = query or ""

	inputpanel.Input:SetText(default or "")
	inputpanel.Input:SetCaretPos(string.len(default or ""))
	inputpanel.Input:RequestFocus()

	inputpanel:Show()

	gace.ext.PushESCListener(function()
		if inputpanel:IsValid() and inputpanel:IsVisible() then
			inputpanel:Hide()
			gace.Frame.BasePanel:InvalidateLayout(true)

			if inputpanel.InputClosedCallback then
				inputpanel.InputClosedCallback()
				inputpanel.InputClosedCallback = nil
			end
		else
			return false -- this callback is invalid
		end
	end)

	if callback then
		inputpanel.InputCallback = callback
	else
		return ATPromise(function(resolver)
			inputpanel.InputCallback = function(text)
				resolver:resolve(text)
			end
			inputpanel.InputClosedCallback = function()
				resolver:reject("input terminated")
			end
		end)
	end
end

function gace.ext.ShowYesNoCancelPrompt(query, callback)
	local function curry(str) return function() callback(str) end end
	Derma_Query(query, "Confirmation", "Yes", curry("yes"), "No", curry("no"), "Cancel", curry("cancel"))
end

function gace.ext.ShowYesCancelPrompt(query, callback)
	local function curry(str) return function() callback(str) end end
	Derma_Query(query, "Confirmation", "Yes", curry("yes"), "Cancel", curry("cancel"))
end
