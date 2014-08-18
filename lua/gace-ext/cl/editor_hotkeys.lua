-- Make it so pressing esc while editor is open hides the editor
local was_esc_down
gace.AddHook("FrameThink", "Hotkey_ESCToHide", function(frame)
	local is_esc_down = input.IsKeyDown(KEY_ESCAPE)
	local esc_pressed = is_esc_down ~= was_esc_down and is_esc_down
	was_esc_down = is_esc_down

	if esc_pressed then
		local function CancelGUIOpen()
			if gui.IsGameUIVisible () then
				gui.HideGameUI ()
			else
				gui.ActivateGameUI ()
			end
		end

		--if gace.InputPanel:IsVisible() then
		--	gace.InputPanel:Hide()
		--	gace.Frame:InvalidateLayout()
		--	CancelGUIOpen()
		--elseif gaceclosewithesc:GetBool() then
			self:SetVisible(false)
			CancelGUIOpen()
		--end
	end
end)