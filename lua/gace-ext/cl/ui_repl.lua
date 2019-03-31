gace.repl = gace.repl or {}

-- A tostring that works better with REPL
function gace.repl.ToString(o, noTableRecursion)
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
	if type(o) == "function" then
		local meta = debug.getinfo(o)
		return string.format("%s (%s at %d)", tostring(o), meta.short_src, meta.linedefined or -1)
	end
	if not noTableRecursion and type(o) == "table" and (not getmetatable(o) or not getmetatable(o).__tostring) then
		local ret = {}
		table.insert(ret, {clr = Color(145, 61, 136), str = string.format("%s\n", tostring(o))})

		local keys = table.GetKeys(o)
		table.sort(keys)
		for _,k in pairs(keys) do
			local v = o[k]

			local kstr, kclr = gace.repl.ToString(k, true)
			table.insert(ret, {str = string.format("%-25s", kstr), clr = kclr})

			table.insert(ret, {str = " = "})

			local vstr, vclr = gace.repl.ToString(v, true)
			table.insert(ret, {str = vstr, clr = vclr})

			table.insert(ret, {str = "\n"})
		end

		return ret
	end
	return tostring(o)
end

local FGCLR = {}
function gace.repl.Out(...)
	local replout
	if IsValid(gace.repl.FloatingREPLFrame) and gace.repl.FloatingREPLFrame:IsVisible() then
		replout = gace.repl.FloatingREPLFrame.REPLBase:GetById("REPLOutput")
	else
		replout = gace.GetPanel("REPLOutput")
	end

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

function gace.repl.PrintReplOut(isServer, ...)
	local replcolor = isServer and Color(255, 127, 0) or Color(124, 178, 129)
	local fout = {replcolor}

	local ret = {...}
	if #ret == 0 then
		fout[2] = "nil"
	else
		-- Stringify all
		for k,v in pairs(ret) do
			-- Separate multiple results
			if k > 1 then fout[#fout+1] = "\t" end

			local str, clr = gace.repl.ToString(v)

			if type(str) == "table" then
				for _,v in pairs(str) do
					-- Set color
					fout[#fout+1] = v.clr or replcolor
					fout[#fout+1] = v.str
				end
			else
				-- Set color
				fout[#fout+1] = clr or replcolor
				fout[#fout+1] = str
			end
		end
	end

	gace.repl.Out(unpack(fout))
end

local clientCtx = {}
-- Override print functions
clientCtx[#clientCtx+1] = " local print, MsgN"
clientCtx[#clientCtx+1] = "do"
clientCtx[#clientCtx+1] = "print, MsgN = gace.repl.Out, gace.repl.Out"
clientCtx[#clientCtx+1] = "end"
clientCtx = table.concat(clientCtx, "\n")

function gace.repl.RunCommand(cmd)
	local allowed = LocalPlayer():IsSuperAdmin() -- we're achieving higher level of using dirty hacks

	if not allowed then
		replout(gace.LOG_ERROR, "Permission denied")
		return
	end

	local fullContext = gace.repl.contextSrc:Replace("$UNIQID", LocalPlayer():UniqueID()) .. clientCtx

	cmd = gace.repl.TransformReplCode(cmd)

	-- First try as expression
	local f = CompileString(fullContext .. "\n return " .. cmd, "gacerepl" .. os.time(), false)

	-- If expression failed, try as is
	if type(f) == "string" then
		f = CompileString(fullContext .. "\n" .. cmd, "gacerepl" .. os.time(), false)
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

	gace.repl.PrintReplOut(false, unpack(ret))
end

local acGlobalExtras = {
	me     = { t = "meta", name = "LocalPlayer" },
	wep    = { t = "meta", name = "Weapon" },
	that   = { t = "meta", name = "Entity" },
	here   = { t = "meta", name = "Vector" },
	there  = { t = "meta", name = "Vector" },
	each   = { t = "meta", name = "function" },
	filter = { t = "meta", name = "function" },
	map    = { t = "meta", name = "function" },
}

local function AddREPLComps(par)
	local console = vgui.Create("RichText")
	console:SetTall(150)
	par:AddDocked("REPLOutput", console, FILL)

	local consoleinput = vgui.Create("GAceCodeInput")
	consoleinput:EnableHistory()
	consoleinput.ACOptions = {
		globalExtras = acGlobalExtras
	}

	local history = util.JSONToTable(cookie.GetString("gace-repl-history") or "[]")
	consoleinput.History = history

	consoleinput.OnEnter = function()
		local code = consoleinput:GetText()
		local runOnServer = input.IsShiftDown()

		replout(runOnServer and Color(255, 127, 0) or Color(135, 211, 124), "> ", FGCLR, code)

		if runOnServer then
			local fcode = code
			gace.SendRequest("lua-runsvrepl", {code = fcode}, function(_, _, pl)
				if pl.err then
					gace.repl.Out("Running code on server failed: ", pl.err)
				else
					gace.repl.PrintReplOut(true, pl.out or {})
				end
			end)
		else
			gace.repl.RunCommand(code)
		end

		consoleinput:SetText("")
		consoleinput:RequestFocus()

		-- Get last 10 history entries and stuff them into cookie
		local lastEntries = {}
		for i=0, 10 do
			local le = consoleinput.History[#consoleinput.History - i]
			if not le then break end
			table.insert(lastEntries, 1, le)
		end
		cookie.Set("gace-repl-history", util.TableToJSON(lastEntries))
	end
	par:AddDocked("REPLInput", consoleinput, BOTTOM)

	-- Print help messages
	local helpclr = Color(127, 127, 127)
	replout(helpclr, "[REPL Help] REPL commands are prefixed by a period. Otherwise input is executed as Lua.")
	replout(helpclr, "[REPL Help] Press 'enter' to run code locally. Press 'shift+enter' to run code on server.")
	replout(helpclr, "[REPL Help] Lua environment has some implicit values to use: " .. table.concat(table.GetKeys(gace.repl.implicitGlobals), ", "))
	replout(helpclr, "[REPL Help] Additionally you can call ents('className') to findByClass, ents(vector) to findCloseBy(vector)")
end

concommand.Add("gace-repl", function()
	local fr = gace.repl.FloatingREPLFrame
	if IsValid(fr) then
		fr:MakePopup()
		fr:SetVisible(true)
	else
		fr = vgui.Create("DFrame")
		fr:SetTitle("G-Ace REPL")
		fr:SetSizable(true)
		fr.Paint = function(_, w, h)
			surface.SetDrawColor(gace.UIColors.frame_bg)
			surface.DrawRect(0, 0, w, h)
		end

		-- Kind of hacky
		gace.repl.FloatingREPLFrame = fr

		local base = fr:Add("DDynPanel")
		fr.REPLBase = base
		base:Dock(FILL)

		AddREPLComps(base)

		fr:SetDeleteOnClose(false)
		fr:SetSize(600, 200)
		fr:Center()

		-- ESTListener stack is only available while g-ace is open, so we need to dupe functionality
		local was_esc_down
		local oldthink = fr.Think
		fr.Think = function(self)
			oldthink(self)
			local is_esc_down = input.IsKeyDown(KEY_ESCAPE)
			local esc_pressed = is_esc_down ~= was_esc_down and is_esc_down
			was_esc_down = is_esc_down

			if esc_pressed then
				if gui.IsGameUIVisible() then
					gui.HideGameUI()
				else
					gui.ActivateGameUI()
				end

				fr:Close()
			end
		end

		fr:MakePopup()
	end

	fr.REPLBase:GetById("REPLInput"):RequestFocus()
end)

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

	AddREPLComps(pnl)
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
