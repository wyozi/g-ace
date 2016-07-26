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

-- List of ESC listeners that ALWAYS exist. "Pre" here means that these are evaluated _before_ normal esc_listener_stack.
local static_pre_esc_listener_stack = {}
function gace.ext.AddStaticPreESCListener(listener)
	table.insert(static_pre_esc_listener_stack, listener)
end

-- Add DMenu listener to post stack
-- This listener closes open DMenus.
-- Because list of active DMenus is only available as an upvalue, we have to use debug table magic

gace.ext.AddStaticPreESCListener(function()
	-- This must be done every time; the upvalue gets re-set after every CloseDermaMenus()
	local name, value = debug.getupvalue(RegisterDermaMenuForClose, 1)

	-- TODO what if the name changes?
	if name == "tblOpenMenus" and type(value) == "table" and #value > 0 then
		CloseDermaMenus()
		return true
	end
	return false
end)

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

		-- First check pre-stack
		for i=#static_pre_esc_listener_stack, 1, -1 do
			local popped = static_pre_esc_listener_stack[i]

			local ret = popped()
			if ret ~= false then
				esc_overridden = true
				break
			end
		end

		-- then check real stack
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
