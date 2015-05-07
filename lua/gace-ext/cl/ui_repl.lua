gace.repl = {}

-- A tostring that works better with REPL
function gace.repl.ToString(o)
	if type(o) == "Vector" then
		return string.format("Vector(%f, %f, %f)", o.x, o.y, o.z)
	end
	if type(o) == "Angle" then
		return string.format("Angle(%f, %f, %f)", o.p, o.y, o.r)
	end
	if type(o) == "table" and o.r and o.g and o.b then
		if o.a and o.a ~= 255 then
			return string.format("Color(%d, %d, %d, %d)", o.r, o.g, o.b, o.a), o
		end
		return string.format("Color(%d, %d, %d)", o.r, o.g, o.b), o
	end
	return tostring(o)
end

local FGCLR = {}
function gace.repl.Out(...)
	local replout = gace.GetPanel("REPLOutput")

	local function setclr(r, g, b)
		if type(r) == "table" then
			g = r.g
			b = r.b
			r = r.r
		end
		replout:InsertColorChange(r,g,b,255)
	end
	local function append(txt)
		replout:AppendText(txt)
	end

	local fgcolor = gace.UIColors["tab_fg"]

	setclr(fgcolor)
	for _,v in pairs({...}) do
		if v == FGCLR then
			setclr(fgcolor)
		elseif type(v) == "table" and v.r and v.g and v.b then
			setclr(v.r, v.g, v.b)
		else
			append(gace.repl.ToString(v))
		end
	end
	append("\n")

	replout:GotoTextEnd()
end
local replout = gace.repl.Out

local upvals = {}
upvals[#upvals+1] = "local me,tr,that,here,there,print"
upvals[#upvals+1] = "do"
upvals[#upvals+1] = "me = LocalPlayer()"
upvals[#upvals+1] = "tr = me:GetEyeTrace()"
upvals[#upvals+1] = "that = tr.Entity"
upvals[#upvals+1] = "here = me:EyePos()"
upvals[#upvals+1] = "there = tr.HitPos"
upvals[#upvals+1] = "print = gace.repl.Out"
upvals[#upvals+1] = "end"
upvals = table.concat(upvals, "\n")

function gace.repl.RunCommand(cmd)
	replout(Color(135, 211, 124), "> ", FGCLR, cmd)

	local allowed = LocalPlayer():IsSuperAdmin() -- we're achieving higher level of using dirty hacks

	if not allowed then
		replout(gace.LOG_ERROR, "Permission denied")
		return
	end

	-- First try as expression
	local f = CompileString(upvals .. "\n return " .. cmd, "gacerepl" .. os.time(), false)

	-- If expression failed, try as is
	if type(f) == "string" then
		f = CompileString(upvals .. "\n" .. cmd, "gacerepl" .. os.time(), false)
	end

	-- Nope, we're all dead
	if type(f) == "string" then
		replout(gace.LOG_WARN, "Compilation failed: ", FGCLR, f)
		return
	end

	local ret = {pcall(f)}
	if ret[1] == false then
		replout(gace.LOG_WARN, "Error: ", FGCLR, ret[2])
		return
	end

	-- Remove success bool
	table.remove(ret, 1)

	local replcolor = Color(124, 178, 129)
	local fout = {replcolor}

	if #ret == 0 then
		fout[2] = "nil"
	else
		-- Stringify all
		for k,v in pairs(ret) do
			-- Separate multiple results
			if k > 1 then fout[#fout+1] = "\t" end

			local str, clr = gace.repl.ToString(v)

			-- Set color
			fout[#fout+1] = clr or replcolor
			fout[#fout+1] = str
		end
	end

	replout(unpack(fout))
end

gace.AddHook("AddPanels", "Editor_AddREPLPanel", function(frame, basepnl)
	local sb = basepnl:GetById("EditorPanel")

	local pnl = sb:AddSubPanel("REPLPanel", BOTTOM)
	pnl:SetTall(180)

	pnl.SetOpened = function(self, b)
		if self.IsOpened == b then return end

		self.IsOpened = b

		self:SetVisible(b)
		basepnl:PerformLayout() -- to make sure there are no "ghost" panels

		if b then
			gace.ext.PushESCListener(function()
				if IsValid(self) and self.IsOpened then
					self:SetOpened(false)
				else
					return false
				end
			end)

			self:GetById("REPLInput"):RequestFocus()
		end

		return b
	end
	pnl:SetOpened(false)

	local console = vgui.Create("RichText")
	console:SetTall(150)
	pnl:AddDocked("REPLOutput", console, FILL)

	local consoleinput = vgui.Create("GAceInput")
	consoleinput:EnableHistory()
	consoleinput.OnEnter = function()
		gace.repl.RunCommand(consoleinput:GetText())

		consoleinput:SetText("")
		consoleinput:RequestFocus()
	end
	pnl:AddDocked("REPLInput", consoleinput, BOTTOM)

	-- Print help messages
	local helpclr = Color(127, 127, 127)
	replout(helpclr, "[REPL Help] REPL commands are prefixed by a period. Otherwise input is executed as Lua.")
	replout(helpclr, "[REPL Help] Press 'enter' to run code locally. Press 'shift+enter' to run code on server.")
	replout(helpclr, "[REPL Help] Lua environment has some implicit upvalues: 'me', 'that', 'here', 'there'")
end)

gace.AddHook("AddActionBarComponents", "ActionBar_REPL", function(comps)
	comps:AddCategory("REPL", Color(210, 77, 87), 75)
	comps:AddComponent {
		text = function()
			local replpnl = gace.GetPanel("REPLPanel")
			return replpnl and replpnl.IsOpened and "Close REPL" or "REPL"
		end,
		width = 100,
		fn = function()
			local replpnl = gace.GetPanel("REPLPanel")
			if replpnl then
				replpnl:SetOpened(not replpnl.IsOpened)
			end
		end
	}
	comps:AddCategoryEnd()
end)
