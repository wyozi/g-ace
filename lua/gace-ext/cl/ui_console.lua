
gace.AddHook("AddPanels", "Editor_AddConsole", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	local consolepanel = sb:AddSubPanel("ConsolePanel", BOTTOM)

	local console = vgui.Create("RichText")
	console:SetTall(150)
	consolepanel:AddDocked("Console", console, FILL)

	local consoleinput = vgui.Create("GAceInput")
	consoleinput:EnableHistory()
	consoleinput.OnEnter = function()
		gace.Log(Color(0, 255, 0), "> ", gace.UIColors["tab_fg"], consoleinput:GetText())
		LocalPlayer():ConCommand("gace " .. consoleinput:GetText())

		consoleinput:SetText("")
		consoleinput:RequestFocus()
	end
	consolepanel:AddDocked("ConsoleInput", consoleinput, BOTTOM)
end)

gace.AddHook("LogMessage", "Console_OverrideOldLogSystem", function(...)
	local console = gace.GetPanel("Console")
	if not console then return end

	local function setclr(r, g, b)
		if type(r) == "table" then
			g = r.g
			b = r.b
			r = r.r
		end
		console:InsertColorChange(r,g,b,255)
	end
	local function append(txt)
		console:AppendText(txt)
	end

	local fgcolor = gace.UIColors["tab_fg"]

	setclr(100,100,100)	append(			"[")
	setclr(fgcolor)	append(os.date(	"%H"))
	setclr(fgcolor)	append(			":")
	setclr(fgcolor)	append(os.date(	"%M"))
	setclr(100,100,100)	append(			"] ")

	setclr(fgcolor)
	for _,v in pairs({...}) do
		if type(v) == "table" then
			setclr(v.r, v.g, v.b)
		else
			append(tostring(v))
		end
	end
	append("\n")

	console:GotoTextEnd()

end)
