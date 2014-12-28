-- Handle overriding escape key.
--
-- If you want to do something when esc is pressed, call gace.ext.PushESCListener
-- with a callback function. Callback will be called once and then removed
--
-- If you return 'false' from the callback, callback will be dismissed as if it
-- never existed and will immediately test the next callback

local esc_listener_stack = {}
function gace.ext.PushESCListener(listener)
	table.insert(esc_listener_stack, listener)
end

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

		local esc_overridden = false

		-- Keep popping esc_listeners until we get something that returns ~=false
		while true do
			local popped = table.remove(esc_listener_stack, #esc_listener_stack)
			if not popped then break end

			local ret = popped()
			if ret ~= false then
				esc_overridden = true
				break
			end
		end

		-- If esc wasnt overridden by extensions, we use it for hiding the frame
		if not esc_overridden then
			frame:SetVisible(false)
		end
		CancelGUIOpen()
	end
end)
